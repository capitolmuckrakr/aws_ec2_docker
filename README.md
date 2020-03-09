This project will create a remote AWS EC2 instance running the latest LTS version of Ubuntu Linux. [Docker Community Edition](https://docs.docker.com/install/linux/docker-ce/ubuntu/) will be installed on the instance and a docker user will be created. While AWS offers multiple services for running and managing containers, this project is meant to provide a simpler alternative for people who want to explore Docker but aren't sure how to start or just want to run a few containers but can't install Docker on their own computers.

You'll need to create a new AWS account if you don't have one.

The installation instructions are written for a user running a terminal with a <b title="The default shell isn't always bash, for example on Ubuntu it's Dash and on Mac OSX Mojave it's zsh. Don't use a plain shell, but bash, zsh, tcsh, fish should all work, though the Docker install script only installs completion for bash.">Bash shell</b> on an internet-connected client computer. If it's not already setup on the client computer, install the [AWS Command Line Interface \(AWS CLI\)](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and configure it for your account. You can also use an alternate AWS IAM profile for the installation if one exists and has been set up in your account credentials \(see [below](#gs_profile) for instructions on how to enable this\).

As an example, we'll put the install scripts into a folder below our "home" directory on our client computer. On Mac OS, the home directory is '/Users/myusername,' on Linux systems it's usually '/home/myusername,' and most systems will drop you right into it when you open a Bash terminal. We'll refer to the home directory using the built-in shortcut '~/' for both Mac and Linux. Note that you can place the directories anywhere you like where your account has full read and write privileges. For example, I create a 'scripts' directory inside my home directory on every system I use and then put my project directories inside it.

To start the installation, open the terminal now and from your home directory, change into whatever directory contains the install scripts:
```
~$ #Your 'prompt' may look different, depending on your client system settings.
~$ #Commands are entered following the '$' sign for most prompts.
~$ #If you're cutting and pasting the commands, paste after the '$' to the end of the line.
~$ cd ~/aws_ec2_docker
```

## Creating and configuring the docker server instance

Before creating our server, we need to choose a key pair, a file containing public and private keys that we will use to access the server. The file name for the key pair should match the key pair name and should be a PEM file with the '.pem' extension. Ideally, it's best not to include any spaces or dashes in the file name.

If you don't already have a key pair in your AWS account you want to use, you can create one or import an existing key by visiting the [key pair page](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#KeyPairs:) in the AWS console, under the EC2 service. For example, visit the page and create a new key pair named 'mykey' and save it using the console dialog window that appears. Move the resulting file named 'mykey.pem' to your client machine and save it in your home directory. You'll need to change the access permissions of the key file to be read-only for just the owner before you can use it. This ensures that the file is only usable under your specific user account. To view and change the permissions, type the following commands:
```
~/aws_ec2_docker$ ls -l ~/mykey.pem # list the file and view its permissions.
-rw-r--r--. 1 myusername myusername 1674 Jul 20 16:00 /home/myusername/mykey.pem #the file can be read or written to by the owner but only be read by anyone else.
~/aws_ec2_docker$
~/aws_ec2_docker$ chmod u=r,g=,o= ~/mykey.pem && ls -l ~/mykey.pem #change the file access permissions and list it again.
-r--------. 1 myusername myusername 1674 Jul 20 16:00 /home/myusername/mykey.pem #access is now read-only and solely for you, the file's owner.
```
You'll need to assign the location of your key pair file to the environment variable PEM. For example, if your key pair file is named 'mykey' and is located in your home directory, you would issue the following command:

```
~/aws_ec2_docker$ export PEM='~/mykey.pem'
```
The server installation script uses default values for parameters used to create the EC2 instance.  Optionally, the default values for one or more parameters can be overwritten by assigning the environment variable for the parameter before running the script, again using the 'export VAR=value' syntax.

The variables and their corresponding default values are listed, along with a description of the parameters they control:

**AMIID** -- the ID of the Amazon Machine Image used to launch the instance. The default is the most recent HVM image from the latest LTS version of Ubuntu Server. When setting a different image, choose an HVM Ubuntu one. You can read more about Amazon Machine Images [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) or search for images [here](https://cloud-images.ubuntu.com/locator/ec2/).

**INSTANCETYPE**='t3a.micro' -- the instance class to use, it determines the processing power and speed for the EC2 server.

**VPCID** -- the virtual private cloud to use. The default VPC for the account or profile will be used unless a different ID is assigned. 

**SGNAME**=dockersg -- the security group name to use for the server, it will be created in the assigned VPC if it doesn't already exist. The install script will also add a new rule to the firewall for the group, opening up port 22 for IP addresses within the installing client's subnet (255.255.255.0). To open other ports for access, assign them to the env var **valid_ports** before running the installation. For example, open ports 22 and 80 by typing the following command:
```
~/aws_ec2_docker$ export valid_ports=( 22 80 )
```

To create and setup the application server, run the script aws_ec2_docker.sh.

    ~/aws_ec2_docker$ bash aws_ec2_docker.sh

The terminal will print out the values set for the server parameters, followed by the message "waiting for i-{alphanumeric ID that uniquely identifies the server} ..."
It will take several minutes for the server to be created and have everything installed.

Once the server is created, the terminal will print out a message. It will look similar to: i-0a123b456cd7e8910 is accepting SSH connections under ec2-1-23-456-789.compute-1.amazonaws.com. The instance id (i-xxxxxxxxx) and URL will be whatever AWS assigned for the server that was just created. The terminal will also print out instructions for shortcut commands to connect to the server or to upload files.

Although the server has been created, it needs a couple of minutes to install and setup Docker. You can monitor the installation progress by connecting to the server and reading the install log. Follow the instructions and enter 'connect' to log in to the server. Once connected, you can follow the setup progress by tailing the install log.

To view the install log as it gets updated, type the following command:
   
   ubuntu@ip-xxx-xx-xx-xxx:~$ tail -f /var/log/instance-setup.log # the default prompt for the new server is derived from its internet address.
   
The information will scroll by very quickly. Once the server is done setting everything up for the application, you'll be disconnected as the server reboots. Wait a few seconds for it to restart and you'll be able to join the server again with the 'connect' command.

Note that the server is firewalled; you'll only be able to access it from the internet address of the client computer you used for the installation. To give other users access, you can add their IP addresses to the security group for the server and the database in the [AWS console](https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#SecurityGroups:sort=desc:ipPermissionsIngress).