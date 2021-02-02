using Amazon.S3;
using Amazon.S3.Model;
using S3Tag = Amazon.S3.Model.Tag;
using Amazon.S3.Transfer;
using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;
using chocolatey;
using chocolatey.infrastructure.app.configuration;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using YamlDotNet.RepresentationModel;

namespace ChocoPacker
{
    class Program
    {
        private string package_bucket = Environment.GetEnvironmentVariable("PACKAGE_BUCKET");
        private string sns_topic = Environment.GetEnvironmentVariable("SNS_INFO");
        private string temp_dir = Environment.GetEnvironmentVariable("TEMP");
        private string system_drive = Environment.GetEnvironmentVariable("SYSTEMDRIVE");
        private string src_dir = Environment.GetEnvironmentVariable("CODEBUILD_SRC_DIR");
        private string src_version = Environment.GetEnvironmentVariable("CODEBUILD_RESOLVED_SOURCE_VERSION");
        private string src_repo = Environment.GetEnvironmentVariable("CODEBUILD_SOURCE_REPO_URL").Replace(".git","");

        private bool package_fail = false;

        private AmazonS3Client s3 = new AmazonS3Client();
        private AmazonSimpleNotificationServiceClient snsClient = new AmazonSimpleNotificationServiceClient();

        string RunGit(string args)
        {
            string git_path = temp_dir + "\\ChocoPackerBuild\\packages\\Git-Windows-Minimal.2.18.0\\tools\\cmd\\git.exe";

            Process git = new Process();

            git.StartInfo.FileName = git_path;
            git.StartInfo.WorkingDirectory = src_dir;
            git.StartInfo.Arguments = args;
            git.StartInfo.CreateNoWindow = true;
            git.StartInfo.UseShellExecute = false;
            git.StartInfo.RedirectStandardOutput = true;
            git.StartInfo.RedirectStandardError = true;

            git.Start();
            git.WaitForExit();
            string git_out = git.StandardOutput.ReadToEnd();
            string git_err = git.StandardError.ReadToEnd();

            if (git_err.Length > 0)
                Console.Error.WriteLine(git_err);

            return git_out;
        }

        string GetBranch(string branches, int index)
        {
            string branch = branches.Split("\r\n".ToCharArray())[index].Trim();

            if (branch.Contains("/"))
            {
                branch = branch.Split('/').Last().Trim();
            }

            return branch;
        }

        List<string> GetPackages(string diffs)
        {
            List<string> packages = new List<string>();
            packages.Add("image-builder-cornell");
            packages.Add("base-cornellstream");

            using (StringReader reader = new StringReader(diffs))
            {
                string line = string.Empty;

                while (line != null)
                {
                    line = reader.ReadLine();

                    if (line != null && line.StartsWith("packages/"))
                    {
                        string package = line.Split('/')[1];

                        if (!package.StartsWith("_") && !packages.Contains(package))
                        {
                            packages.Add(package);
                        }
                    }
                }
            }

            return packages;
        }

        private Dictionary<string, string> ReadPackageConfig(string branch, string package)
        {
            string package_dir = $"{this.system_drive}\\{package}";
            string package_yaml = $"{package_dir}\\config.yml";

            Dictionary<string, string> package_config = new Dictionary<string, string>();

            StringReader yaml_text = new StringReader(File.ReadAllText(package_yaml));
            YamlStream yaml = new YamlStream();
            try {yaml.Load(yaml_text);}
            catch (Exception e){
                Console.WriteLine("{0} Exception caught.", e);
                this.AlertFailure(branch, package, e.ToString());
                package_fail = true;
            }
            YamlMappingNode package_root = (YamlMappingNode)yaml.Documents[0].RootNode;

            string[] keys_of_interest = { "Id", "Version", "Description"};
            foreach (var entry in package_root.Children)
            {
                string entry_key = ((YamlScalarNode) entry.Key).Value;

                if (keys_of_interest.Contains(entry_key))
                {
                    string entry_value = ((YamlScalarNode) entry.Value).Value;
                    package_config.Add(entry_key, entry_value);
                }

            }

            return package_config;
        }

        private void WritePackageNuspec(string branch, string package, Dictionary<string, string> package_config)
        {
            string package_dir = $"{this.system_drive}\\{package}";
            string package_nuspec = $"{package_dir}\\package.nuspec";

            XmlWriter x = XmlWriter.Create(package_nuspec);

            x.WriteStartDocument();
            x.WriteStartElement("package", "http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd");

                x.WriteStartElement("metadata");

                    x.WriteStartElement("id");
                    x.WriteString(package_config["Id"]);
                    x.WriteEndElement();

                    x.WriteStartElement("version");
                    x.WriteString(package_config["Version"]);
                    x.WriteEndElement();

                    x.WriteStartElement("title");
                    x.WriteString(package_config["Id"]);
                    x.WriteEndElement();

                    x.WriteStartElement("authors");
                    x.WriteString("Marty J. Sullivan");
                    x.WriteEndElement();

                    x.WriteStartElement("tags");
                    x.WriteString(package_config["Id"]);
                    x.WriteEndElement();

                    x.WriteStartElement("summary");
                    x.WriteString(package_config["Description"]);
                    x.WriteEndElement();

                    x.WriteStartElement("description");
                    x.WriteString(package_config["Description"]);
                    x.WriteEndElement();

                x.WriteEndElement();

                x.WriteStartElement("files");

                    x.WriteStartElement("file");
                    x.WriteAttributeString("src", "tools\\**");
                    x.WriteAttributeString("target", "tools");
                    x.WriteEndElement();

                    x.WriteStartElement("file");
                    x.WriteAttributeString("src", "icons\\**");
                    x.WriteAttributeString("target", "tools\\icons");
                    x.WriteEndElement();

                    x.WriteStartElement("file");
                    x.WriteAttributeString("src", "config.yml");
                    x.WriteAttributeString("target", "tools\\config.yml");
                    x.WriteEndElement();

                    x.WriteStartElement("file");
                    x.WriteAttributeString("src", $"{this.src_dir}\\packages\\_common\\chocolateyinstall.ps1");
                    x.WriteAttributeString("target", "tools\\chocolateyinstall.ps1");
                    x.WriteEndElement();

                x.WriteEndElement();

            x.WriteEndElement();
            x.WriteEndDocument();
            x.Close();
        }

        private void WritePackageInstaller(string branch, string package)
        {
            string package_dir = $"{this.system_drive}\\{package}";
            string local_zip = $"{this.temp_dir}\\{package}.zip";
            string installer_prefix = $"installers/master/{package}.zip";
            string tools_dir = $"{package_dir}\\tools";
            string installer_dir = $"{tools_dir}\\installer";

            ListObjectsV2Request list_req = new ListObjectsV2Request
            {
                BucketName = this.package_bucket,
                Prefix = installer_prefix,
            };

            ListObjectsV2Response list_resp = this.s3.ListObjectsV2(list_req);

            if (list_resp.KeyCount == 1)
            {
                S3Object s3_zip = list_resp.S3Objects[0];
                TransferUtility s3_transfer = new TransferUtility();

                TransferUtilityDownloadRequest download_req = new TransferUtilityDownloadRequest
                {
                    BucketName = s3_zip.BucketName,
                    Key = s3_zip.Key,
                    FilePath = local_zip,
                };

                Console.WriteLine($"Downloading s3://{this.package_bucket}/{installer_prefix} to {local_zip}...");

                try {s3_transfer.Download(download_req);}
                catch (Exception e){
                    Console.WriteLine($"ERROR: Downloading s3://{this.package_bucket}/{installer_prefix} to {local_zip}...");
                    Console.WriteLine("{0} Exception caught.", e);
                    this.AlertFailure(branch, package, e.ToString());
                    package_fail = true;
                }
                
                Console.WriteLine("Free space of C: " + PercentageFreeSpace("C"));
                Console.WriteLine($"Extracting {local_zip} to {installer_dir}...");

                try {
                    Directory.CreateDirectory(installer_dir);
                    ZipFile.ExtractToDirectory(local_zip, installer_dir);
                    File.Delete(local_zip);
                }
                catch (Exception e){
                    Console.WriteLine($"ERROR: Extracting {local_zip} to {installer_dir}...");
                    Console.WriteLine("{0} Exception caught.", e);
                    this.AlertFailure(branch, package, e.ToString());
                    package_fail = true;
                }
            }
        }

        private void WriteChocoPackage(string branch, string package, Dictionary<string, string> package_config)
        {
            string package_dir = $"{this.system_drive}\\{package}";
            string package_nuspec = $"{package_dir}\\package.nuspec";
            string pack_args = $"{package_nuspec}";
            string local_nupkg = $"{package_dir}\\{package}.{package_config["Version"]}.nupkg";

            GetChocolatey choco = new GetChocolatey();

            try{
                choco.Set(c => {
                    c.CommandName = "pack";
                    c.Input = pack_args;
                    c.OutputDirectory = package_dir;
                }).Run();
            }
            catch (Exception e) {
                Console.WriteLine($"ERROR: Building {package}...");
                Console.WriteLine("{0} Exception caught.", e);
                this.AlertFailure(branch, package, e.ToString());
                package_fail = true;
            }

            // if (File.Exists(local_nupkg)){return true;}
            // else {return false;}
        }

        private void PutChocoPackage(string branch, string package, Dictionary<string, string> package_config)
        {
            string package_dir = $"{this.system_drive}\\{package}";
            string local_nupkg = $"{package_dir}\\{package}.{package_config["Version"]}.nupkg";
            string s3_nupkg = $"packages/{branch}/{package}.{package_config["Version"]}.nupkg";
            string tag1_name = "Temporary";
            string tag1_value = "True";
            
            if (branch.Equals("master")) {   
                tag1_value = "False";
            }

            TransferUtility s3_transfer = new TransferUtility();
            
            TransferUtilityUploadRequest upload_req = new TransferUtilityUploadRequest
            {
                BucketName = this.package_bucket,
                Key = s3_nupkg,
                FilePath = local_nupkg,
                TagSet = new List<S3Tag>{
                    new S3Tag {Key = tag1_name, Value = tag1_value}
                }
            };

            Console.WriteLine($"Uploading s3://{this.package_bucket}/{s3_nupkg}...");

            try{
                s3_transfer.Upload(upload_req);
            }
            catch (Exception e){
                Console.WriteLine($"ERROR: Uploading s3://{this.package_bucket}/{s3_nupkg}...");
                Console.WriteLine("{0} Exception caught.", e);
                this.AlertFailure(branch, package, e.ToString());
            }
        }

        private void CleanupPackage(string branch, string package, Dictionary<string, string> package_config)
        {
            string package_dir = $"{this.system_drive}\\{package}";
            string local_nupkg = $"{package_dir}\\{package}.{package_config["Version"]}.nupkg";
            string tools_dir = $"{package_dir}\\tools";
            string installer_dir = $"{tools_dir}\\installer";
            string package_nuspec = $"{package_dir}\\package.nuspec";

            if (File.Exists(local_nupkg)) {
                File.Delete(local_nupkg);
            }

            File.Delete(package_nuspec);

            if (Directory.Exists(installer_dir))
                Directory.Delete(installer_dir, true);
        }

        private void AlertSuccess(string branch, string package)
        {
            if (package!="image-builder-cornell")
            {
                PublishRequest publishRequest = new PublishRequest(this.sns_topic, $"SUCCESS: Build for {package} on {branch} branch successfully packaged!");
                PublishResponse publishResponse = snsClient.Publish(publishRequest);

                // Print the MessageId of the published message.
                Console.WriteLine($"Sending success build SNS for {package}; MessageId: " + publishResponse.MessageId);
            }
        }

        private void AlertFailure(string branch, string package, string error)
        {
            PublishRequest publishRequest = new PublishRequest(this.sns_topic, $"FAILED: Build for {package} on {branch} branch...\n\n{error} \n\n{src_repo}/commit/{src_version}");
            PublishResponse publishResponse = snsClient.Publish(publishRequest);

            // Print the MessageId of the published message.
            Console.WriteLine($"Sending failed build SNS for {package}; MessageId: " + publishResponse.MessageId);
            package_fail = true;
        }
        
        private double PercentageFreeSpace(string driveLetter)
        {
            try
            {
                DriveInfo drive = new DriveInfo(driveLetter);
                return drive.AvailableFreeSpace;
            }
            catch
            {
                // Return -1 when the drive is not accessible (gives an `IOException`)
                // or when the drive letter is invalid, in which case `DriveInfo()` generates
                // an error of type `ArgumentException`.
                return -1;
            }
        }

        void App()
        {
            string branches = this.RunGit("branch -a --contains " + this.src_version);
            string branch = this.GetBranch(branches, 1);
            string diffs = this.RunGit("show --name-only");
            List<string> packages = this.GetPackages(diffs);

            Console.WriteLine($"Using Branch: {branch}");

            if (packages.Count() == 0)
            {
                Console.WriteLine($"No changes to packages in commit {this.src_version}, exiting...");
            }

            foreach (string package in packages)
            {
                string package_dir = $"{this.src_dir}\\packages\\{package}";
                string temp_package_dir = $"{this.system_drive}\\{package}";

                if (!Directory.Exists(package_dir))
                {
                    Console.WriteLine($"{package} doesn't exist in repository for commit {this.src_version}, skipping...");
                    continue;
                }

                Console.WriteLine($"Moving Package Directory to: {temp_package_dir}");
                Directory.Move(package_dir, temp_package_dir);

                Console.WriteLine($"Building Package: {package}");
                try {
                    Dictionary<string, string> package_config = this.ReadPackageConfig(branch, package);

                    this.WritePackageNuspec(branch, package, package_config);
                    this.WritePackageInstaller(branch, package);

                    this.WriteChocoPackage(branch, package, package_config);
                    this.PutChocoPackage(branch, package, package_config);

                    this.CleanupPackage(branch, package, package_config);
                    if (!package_fail){this.AlertSuccess(branch, package);}
                    Console.WriteLine(" ");
                    Console.WriteLine($"SUCCESS: Built {package}");
                }
                catch (Exception e){
                    Console.WriteLine(" ");
                    Console.WriteLine($"FAILED: {package}");
                    Console.WriteLine("{0} Exception caught.", e);
                    package_fail = true;
                }
            }
            
            // If any packages failed set variable flag for post_build stage
            if (package_fail){
                Environment.SetEnvironmentVariable("PACKAGES_INSTALLED", "1", EnvironmentVariableTarget.Machine);
                Console.WriteLine(Environment.GetEnvironmentVariable("PACKAGES_INSTALLED", EnvironmentVariableTarget.Machine));
            }

        }

        static void Main(string[] args)
        {
            new Program().App();
        }
    }
}
