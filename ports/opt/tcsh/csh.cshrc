#
# /etc/csh.cshrc: tcsh(1) configuration
#

if ( "$uid" == "0" ) then
	setenv PATH "/sbin:/usr/sbin:/bin:/usr/bin:/opt/bin"
else
	setenv PATH "/bin:/usr/bin:/opt/bin"
endif

if ( ! -f ~/.inputrc ) then
	setenv INPUTRC "/etc/inputrc"
endif

setenv LESSCHARSET "latin1"
setenv LESS "-R"
setenv CHARSET "ISO-8859-1"
set prompt="%B$ "

umask 022

# End of file
