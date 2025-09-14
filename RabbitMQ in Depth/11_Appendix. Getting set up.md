# Appendix. Getting set up

This appendix covers setting up VirtualBox, Vagrant, and the RabbitMQ in Depth Vagrant virtual machine (VM) that contains everything needed to test code samples, experiment, and follow along with the book.

VirtualBox is the virtualization software we’ll use to run all of the examples, and Vagrant is an automation tool for setting up the VM. You’ll need to install these two applications, and then you’ll be able to set up the RabbitMQ in Depth VM by downloading a zip file containing the Vagrant configuration and Chef cookbooks. Once they’re downloaded and extracted, you can start the VM by running a single command, and you’ll be able to interactively test the code listings and examples in the book.

It’s a fairly straightforward process in Windows, OS X, and Linux designed to keep the steps for following along with the book to a minimum. To get started, you’ll need to download and install VirtualBox.

### A.1. Installing VirtualBox

VirtualBox is a free virtualization product originally developed by Sun Micro-systems and now made available by Oracle. It runs on Windows, Linux, Macintosh, and Solaris systems and provides the underlying VM that will be used for this book.

Setting up VirtualBox is very straightforward. You can download it from [http://virtualbox.org](http://virtualbox.org/). Just navigate to the Downloads page, chose the VirtualBox platform package for your operating system type, and download the installation package for your computer ([figure A.1](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig01)).

![Figure A.1. The VirtualBox download page includes downloads for Windows, OS X, Linux, and Solaris.](https://drek4537l1klr.cloudfront.net/roy/Figures/afig01_alt.jpg)

##### Note

At the time of this writing, Vagrant supports VirtualBox versions 4.0.x, 4.1.x, 4.2.x, 4.3.x, 5.0.x, and 5.1.x. It’s a safe assumption that with the popularity of both VirtualBox and Vagrant that Vagrant will continue to support new releases from the VirtualBox project shortly after they’re released. In other words, you should be able to download the most current version of VirtualBox without concern for Vagrant incompatibility.

With the package downloaded, run the installer. Although each operating system will look slightly different, the installation process should be the same. It’s safe in most circumstances to follow the default installation options when running the wizard ([figure A.2](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig02)).

![Figure A.2. The VirtualBox installation wizard](https://drek4537l1klr.cloudfront.net/roy/Figures/afig02_alt.jpg)

If you’d like a more in-depth walkthrough of the options available for installing VirtualBox, [chapter 2](https://livebook.manning.com/book/rabbitmq-in-depth/chapter-2/ch02) of the VirtualBox user manual covers installation in a very detailed manner and is available at [www.virtualbox.org/manual/ch02.html](http://www.virtualbox.org/manual/ch02.html).

Should you run into problems installing VirtualBox, the best place for support is the VirtualBox community. The mailing lists, forums, and #vbox IRC channel on [www.Freenode.net](http://www.freenode.net/) are all excellent resources to get you up and running if you run into any issues.

Assuming that you didn’t run into any problems installing VirtualBox, you should now install Vagrant, the virtual environment automation tool.

### A.2. Installing Vagrant

Vagrant is an automation tool for managing virtual environments. It allows for VMs to be provisioned from scratch, providing a structure for downloading and installing a base VM image, and it integrates with configuration management tools like Chef and Puppet. The result is a consistently deployed VM that makes for a solid development environment. In addition, because it’s run on your local machine, it maps network access to the services running in the VM to your local computer’s `localhost` network interface. This functionally makes it appear as if RabbitMQ and the other network-based tools you’ll be using in this book are running natively on your computer instead of in a VM.

To get started, visit [www.vagrantup.com](http://www.vagrantup.com/) ([figure A.3](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig03)) in your web browser and download the version of Vagrant appropriate for your computer.

![Figure A.3. VagrantUp.com, home of the Vagrant project](https://drek4537l1klr.cloudfront.net/roy/Figures/afig03_alt.jpg)

When you click on the Download button, you’ll be presented with a list of versions to download. Click on the latest version at the top of the list, and then you’ll be presented with a list of installers and packages for specific operating systems ([figure A.4](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig04)). Select the version that’s appropriate for your computer and download it.

##### Note

Although VirtualBox supports Solaris as a host operating system, Vagrant only supports Windows, OS X, and a handful of Linux distributions.

![Figure A.4. The Vagrant download page](https://drek4537l1klr.cloudfront.net/roy/Figures/afig04_alt.jpg)

Setting up Vagrant is a straightforward process. Windows and OS X users will run the installation tool ([figure A.5](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig05)), whereas Linux users will install the package appropriate for their distribution using a package tool like dpkg or rpm. If you have any installation issues, the Vagrant website has support documentation available at [http://docs.vagrantup.com/](http://docs.vagrantup.com/).

![Figure A.5. The Vagrant installation wizard](https://drek4537l1klr.cloudfront.net/roy/Figures/afig05_alt.jpg)

When the installation is complete, the Vagrant command-line application should be added to the system path. If you find that it’s not available in your terminal or shell (PowerShell in Windows), you may have to log out and back in to your computer. If you aren’t able to run the Vagrant command-line application after logging out and back in, there’s both professional and community-based support for Vagrant. It’s best to start with the community options via the mailing list or in the #vagrant IRC channel on [www.Freenode.net](http://www.freenode.net/).

If you’ve not used Vagrant before, it’s a great tool and is really helpful in the development process. I highly recommend reading the documentation and playing around with the various commands it has available. Try typing `vagrant help` to see a list of what you can do with a Vagrant-controlled VM.

If you’ve successfully installed Vagrant, you should now set up the VM for RabbitMQ in Depth by downloading the appropriate files and running a few simple commands.

### A.3. Setting up the Vagrant virtual machine

For this next step, you’ll need to download a small zip file containing the Vagrant configuration and support files required for the virtual environments used in the book. There are multiple VMs defined in the Vagrant file for the clustering tutorials in part 2 of the book. You’ll be using the primary VM unless instructed otherwise in a chapter.

To get started, you’ll need to download the Vagrant configuration file, rmqid-vagrant.zip, from the code files in order to configure the environment.

Once you have the zip file downloaded, extract the contents of the file to a directory that will be easy for you to remember and access via your terminal, or PowerShell if you’re a Windows user. When you extract the zip file, the files will be located in a directory named rmqid-vagrant. Open your terminal and navigate to this directory, and start the Vagrant setup of the primary VM by typing the following:

```
vagrant up primary
```

This process will take 10 to 15 minutes on average but can vary depending on the speed of your computer and internet connection. When you first start the process, you should see output on your console indicating the progress of the VM, looking something similar to the following:

```
12345678910111213141516171819202122Bringing machine 'primary' up with 'virtualbox' provider...
==> primary: Box 'gmr/rmqid-primary' could not be found. Attempting to find and install...
    primary: Box Provider: virtualbox
    primary: Box Version: >= 0
==> primary: Loading metadata for box 'gmr/rmqid-primary'
    primary: URL: https://atlas.hashicorp.com/gmr/rmqid-primary
==> primary: Forwarding ports...
    primary: 1883 => 1883 (adapter 1)
    primary: 22 => 2222 (adapter 1)
==> primary: Booting VM...
==> primary: Waiting for machine to boot. This may take a few minutes...
    primary: SSH address: 127.0.0.1:2222
    primary: SSH username: vagrant
    primary: SSH auth method: private key
==> primary: Running provisioner: shell...
    primary: Running: inline script
==> primary: stdin: is not a tty
==> primary: From https://github.com/gmr/RabbitMQ-in-Depth
==> primary:  * branch            master     -> FETCH_HEAD
==> primary:    80e7615..469fc8c  master     -> origin/master
==> primary: Updating 80e7615..469fc8c
==> primary: Fast-forward
```

If you didn’t see output similar to this, you may have an application on your computer that’s already bound to and listening on one of the ports the VM is trying to use. If you’re running RabbitMQ already on your local machine, shut it down before trying to run `vagrant up` again. The VM will attempt to use ports 1883, 2222, 5671, 5672, 8883, 8888, 9001, 15670, 15671, 15672, and 61613. That’s a lot of ports, but in this machine you’re running a virtual server with several services for the examples in this book. You’ll need to stop any applications that are listening on these ports in order to get the VM working properly.

Additionally, if you’re setting up on a Windows machine, you may be prompted by your firewall to allow connections to and from the VM. Make sure you allow this, or you’ll be unable to connect to the VM, and Vagrant won’t even be able to configure it.

If everything started OK and the machine has booted, there may be points while it is configuring the VM when it appears stalled or not doing anything. Once the setup of the VM is complete, you should be back at the prompt in your console.

Finally, if you need to stop the VM, use the command `vagrant halt`.

Now you can test a few URLs in your browser to confirm that everything was set up properly.

### A.4. Confirming your installation

There are two applications you need to ensure are properly set up. If they’re set up properly, it’s an indication that everything worked as expected and you can go ahead and start with the examples in the book.

The first is RabbitMQ. To test that RabbitMQ is set up properly, open your browser to http://localhost:15672. You should see a screen similar to [figure A.6](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig06).

![Figure A.6. The RabbitMQ management interface login](https://drek4537l1klr.cloudfront.net/roy/Figures/afig06_alt.jpg)

The username and password for logging into the management UI are the default “guest” and “guest”. If you log in, you’ll get the main screen of the management UI, which gives an overview of the server configuration and status.

With RabbitMQ confirmed, the other application to test is the IPython Notebook server. This application allows you to run the Python-based code samples interactively in your web browser. With this VM, all of the code listings and samples are organized in the IPython Notebook server, allowing you to open each and run them independently of each other. The IPython Notebook server should be listening on port 8888, so open a new tab in your web browser and visit http://localhost:8888. You should see a page similar to the one in [figure A.7](https://livebook.manning.com/book/rabbitmq-in-depth/appendix/app01fig07).

![Figure A.7. The IPython Notebook server index page with the RabbitMQ in Depth notebooks](https://drek4537l1klr.cloudfront.net/roy/Figures/afig07_alt.jpg)

If you’re interested in the capabilities of or in documentation for the IPython Notebook server, the project’s website contains a wealth of information ([http://ipython.org](http://ipython.org/)). It’s a tremendously useful application and is gaining popularity in scientific and data-processing communities as an interface for crunching datasets and performing data visualization.

### A.5. Summary

At this point you should have the RabbitMQ in Depth VM up and running. You installed VirtualBox, the virtual environment automation tool. By downloading the RabbitMQ in Depth Vagrant configuration and Chef cookbooks, you should have been able to start up a new VM using the `vagrant up` command. With these steps done, you can now proceed to using the tools in the VM to follow along with the examples in the book.
