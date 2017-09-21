# Creating NetBSD images for Google Compute Engine

This repository holds tools to build a NetBSD image for use on Google Compute
Engine (GCE). GCE is part of the Google Cloud Platform.

## Running `make.bash`

`make.bash` can be run under a GNU/Linux, BSD or macOS operating system.  To run
the script, you need a few things to be installed:

* bash
* qemu
* cdrtools
* GNU tar (http://pkgsrc.se/archivers/gtar)
* GNU coreutils (http://pkgsrc.se/sysutils/coreutils)
* Python 2.7
* python-pexpect (http://pkgsrc.se/devel/py-pexpect)

When you run

```
bash ./make.bash
```

it will download a distfile for Anita (an automated NetBSD installation tool),
which will download and install NetBSD 8_BETA in a virtual machine on the local
host. It then adds several tweaks to ensure that networking and storage will
work on GCE and packs the image into a tar.gz file.

Optionally, you can give the script an architecture (`i386` or `amd64`) and a
branch name as parameters, for example

```
bash ./make.bash amd64 HEAD
```

to install a 64-bit version of NetBSD-current.

**NOTE:** NetBSD versions older than 7.1-RC1 will not work at all, however all
NetBSD-7 releases are currently quite unstable. NetBSD-8 and NetBSD-current are
recommended.

**NOTE:** The image will not boot under Anita once the script has finished. This
is because qemu emulates an IDE hard drive while Google Persistent Disk uses the
`vioscsi` driver.

## How to use the created image (i.e. how to get started on GCE)

The how-to below describes how to do the required operations in a web browser.
You can also use the [Google Cloud SDK](https://cloud.google.com/sdk/) and its
`gcloud` command line tool.

1.  Run `make.bash` as described above.
2.  Go to https://cloud.google.com/. Log in with your Google account or
    create a new one. If you never used Google Cloud Platform before, you will
    need to enter a credit card for billing. Yes, running stuff on GCP costs
    money.
3.  Create a new Cloud project. A project is a collection of resources, such as
    VMs, storage, logs, etc.
4.  In the left hand menu, click "Storage" and create a new bucket.
5.  Click on the bucket, then click the "Upload files" button and select the
    output file that was created in step 1 (e.g. `netbsd-amd64-gce.tar.gz`).
6.  In the left hand menu, select "Compute Engine", then "Images". Click "Create
    Image", choose a name, and select "Cloud Storage file" as the source. Browse
    to the file you just uploaded.
7.  Select "Instances" from the left hand menu, then "Create Instance". Select a
    zone and the amount of CPU and memory. Under the "Boot Disk" heading, click
    "Change", select "Custom images" and choose the image you just created.
    Click the "Create" button at the bottom.
8.  You will be transported back to the list of instances, where the instance
    you created is just starting up. Congratulations! To see the console output,
    click on the instance name, scroll down and click on "View serial port".

## Using the interactive serial console

You will soon notice that you cannot use the SSH button to connect to the VM.
Unfortunately, transferring of SSH keys to the machine does not work yet. To
connect to the instance now, you can use the interactive serial console. Click
"Edit" on the instance details page, scroll all the way to the bottom and tick
the "Enable connecting to serial ports" box.

Now you can click the button labeled "Connect to serial port". You will get a
terminal window in the browser. Log in as `root` with no password. (This is the
first thing you should change!)

Now you can create user accounts and copy SSH keys as you wish. For example, to
create a user named `myuser`, use the following commands:

```
useradd -m myuser
passwd myuser
```

To enable the SSH daemon, use the following commands:

```
echo sshd=YES >> /etc/rc.conf
/etc/rc.d/sshd start
```

Once sshd is running, you should be able to connect to the instance by pointing
your ssh client to the instance's external IP address.
