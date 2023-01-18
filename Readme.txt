ZeroChEN

ZeroChEN is an English translation of 0ch+, a Japanese textboard script modeled off of 2ch.

Translations are currently around 75% done. Almost the entirity of the front facing portion is complete.


    ADDENUM
    	>Why am I getting error 500s?
	This is due to either two things, a misconfigured Apache/NGINX config or a permissions error.

	If a permissions error, make sure that
	the root folder is 777
	/test is 777
	all .cgi files are 755
	all folders inside of test are 777.
	users.cgi (/test/info/users.cgi) is 777.
	Alternatively, you can chown everything to www-data if you not using it for a production environment.
	
Below is the original README for 0ch+
----------------------------------

Zero-Channel Plus Ver. 0.7.5 - Readme.txt

Official WEB : http://zerochplus.sourceforge.jp/


■Preface
　This file is a description of "Zero-channel Plus," a project started to modify the script of the original Zero-channel (http://0ch.mine.nu/) to 2channel specifications.
This file is an instruction manual for the project "Zero-Channel Plus", which started with the purpose of modifying the script of the original Zero-Channel () to 2Channel specifications.
　I'd like to explain it in a way that anyone can understand, but I'm a bit of a lazy creator, so there may be some things I haven't gotten to yet.
I hope that anyone can understand it, but I am a bit of a lazy creator, so please understand that I may not be able to explain it well enough.
　This file has been edited based on /readme/readme.txt of the original Zero-Channel, so some parts of the file are still in the original text.
Please note that some parts of this file are the same as the original text. Please be aware that some parts of the file may be left as they were in the original.


What is Zero-Channel Plus?
　Zero-channel Plus is an improved version of Zero-channel, a Perl script that operates a thread float type bulletin board.
This is an improved version of Zero-Channel.
　Originally, the purpose of Zero-channel Plus was to remodel a group of bulletin boards that had been created using the Zero-channel script, but the script was not modified properly, so it was reworked.
The purpose was to re-create a group of boards that had been modified using the Zero-Channel script, but we decided to make it available to others anyway.
However, we decided to open it to the public this time because we wanted to let other people use it.
　As with Zero-chan, you can write and view messages using a dedicated 2channel browser.


System Requirements
  Required Environment
    Perl 5.8 or higher (Perl 6 is not included) or its distribution software is required.
      Perl 5.8 or higher (not including Perl 6) or OS on which the distribution software runs.
    Disk space of 5 MB or more 
  Recommended Environment
    An OS that has an Apache HTTP Server capable of CGI operation with suEXEC and running Perl 5.8 or higher (Perl 6 is not included).
      Perl 5.8 or higher (Perl 6 is not included).
    Disk space of 10 MB or more

■Distribution File Structure
zerochplus_x.x.x/
 + Readme/ - the file you should read first
 | + ArtisticLicense.txt
 | + Readme.txt - Readme file for zerochplus (this is it)
 | + Readme0ch.txt - Readme file for Zero-Channel (the original)
 |test/ - test/ - readme file for Zero-Channel Plus (this is it)
 + test/ - Zero-channel Plus working directory
    + *.cgi - CGI for basic operation
    + datas/ - initial and fixed data storage
    | + 1000.txt
    + + 2000000000.dat
    | :
    + info/
    | + category.cgi - initial definition file of BBS categories
    | + errmes.cgi - Error message definition file
    | + users.cgi - initial user (Administrator) definition files
    + module/
    | + *.pl - Zero-channel module
    + mordor/
    | + *.pl - module for admin CGI
    + plugin/
    | + 0ch_*.pl - plugin script
    + perllib/
       + * - packages required for Zero-channel Plus

How to install
　The installation instructions with images are available on the Wiki.
  Install - Zero-channel Plus Wiki
    http://sourceforge.jp/projects/zerochplus/wiki/Install

1.Change the script

	Open the .cgi file directly under the configuration file test, and change the perl path
	  to match your environment.
	
	Change the following location.
	
		#! /usr/bin/perl

2. Upload the script

	Upload all the configuration files under test to the installation server.
	After uploading, set the permissions to the appropriate values.
	
	Refer to the following page for permission values.
	Permission - Zero-channel Plus
	  http://sourceforge.jp/projects/zerochplus/wiki/Permission

3. Configuration

	Access [installation server]/test/admin.cgi.
	Log in with the user name "Administrator" and the path "zeroch".
	Select the "System Settings" menu at the top of the screen.
	Select the "Basic Settings" menu on the left side of the screen.
	Set the item "Active Server" to an appropriate value and click the "Set" button.
	Select the "Basic Settings" menu on the left side of the screen again, and confirm that the active server has been updated.
	  Please make sure that the active server has been updated (if it has not, please check the permissions).
	  (If not, there may be a problem with the permission settings.)
	Select the "User" menu at the top of the screen.
	Select "Administrator" in the "User Name" column in the center of the screen.
	Change the user name and password, and press the "Set" button.
	Select "Logoff" at the top of the screen.

4. Create a BBS

	Log in as the administrator user you have just set up.
	Select the "BBS" menu at the top of the screen.
	Select the "Create Message Board" menu on the left side of the screen.
	Fill in the required information and click the "Create" button.

BBS Settings

	Select "BBS" menu at the top of the screen.
	Select a message board from the list of message boards.
	Select "BBS Settings" at the top of the screen.
	Select "BBS Settings" at the top of the screen.

Select "BBS Settings" at the top of the screen. -----------------------------------------------------------------------
Note
	Please be sure to change the Administrator user after installation. Immediately after installation, the user name and password are fixed.
	  If left unchecked, there is a risk that someone other than the administrator will be able to log in with administrative privileges.
	  If left unchecked, there is a risk that someone other than the administrator may log in with administrative privileges.
-----------------------------------------------------------------------


License
　The license of this script is the same as that of the original Zerochanne. The following is the license of the original Zero-chan.
The following is a quotation from /readme/readme.txt.

> This script may be freely modified and redistributed. You are free to modify and redistribute this script.
You may also use this script with the credit (version) and other indications output by this script removed.
> However, the author does not waive copyrights on this script and accompanying files. The author will not be liable for any trouble that may occur in connection with the use of this script.
The author is not responsible for any trouble that may occur in connection with the use of this script.

　The copyright and license of "make.cgi" belongs to another person, and the copyright and license of "make.cgi" belongs to the author of "make.cgi".
The copyright and license belongs to the author of the "make.cgi" file.

　The packages included in perllib are described below.

Version Upgrade
　Starting from 0.7.0, we will notify you on the admin page when we upgrade the version of the software.
　Please update your software frequently as there are many updates including security fixes.
Please update your software frequently.


Help and Support
　For more detailed information, please refer to the following pages.
  Help - Zero-channel Plus
    http://zerochplus.sourceforge.jp/help/
  Zero-channel Plus Wiki
    http://sourceforge.jp/projects/zerochplus/wiki/

　If you do not find the information you are looking for on the above pages, or if you would like to report a problem, please contact us at
Please contact us from below.
  Support - Zero-channel Plus
    http://zerochplus.sourceforge.jp/support/

Acknowledgements
　We would like to thank everyone who has helped us in the creation of Zero-Channel Plus.
　And above all, I would like to thank Mr. Mental Decline who created the original script ZeroChannel.
I would like to thank Mr. Mental Decline who created the original script Zero-Channel Plus.

Official WEB
　http://zerochplus.sourceforge.jp/

Packages in perllib
　These are the packages required to run Zero-channel Plus. Some servers may already have them installed.
but we include them here just in case.
　Here are the details of the packages

Digest-SHA-PurePerl
Perl implementation of SHA-1/224/256/384/512
    Version: 5.72
    Released: 2012-09-24
    Author: Mark Shelor <mshelor@cpan.org>
    License: The Perl 5 License (Artistic 1 & GPL 1)
    CPAN: http://search.cpan.org/dist/Digest-SHA-PurePerl-5.72/

Net-DNS-Lite
a pure-perl DNS resolver with support for timeout
    Version: 0.09
    Released: 2012-06-20
    Author: Kazuho Oku <kazuhooku@gmail.com>
    License: The Perl 5 License (Artistic 1 & GPL 1)
    CPAN: http://search.cpan.org/dist/Net-DNS-Lite-0.09/

List-MoreUtils
Provide the stuff missing in List::Util
    Version: 0.33
    Released: 2011-08-04
    Author: Adam Kennedy <adamk@cpan.org>
    License: The Perl 5 License (Artistic 1 & GPL 1)
    CPAN: http://search.cpan.org/dist/List-MoreUtils-0.33/

CGI-Session
Persistent session data in CGI applications
    Version: 4.48
    Released: 2011-07-11
    Author: Mark Stosberg <mark@summersault.com>
    License: Artistic License 1.0
    CPAN: http://search.cpan.org/dist/CGI
    
