#============================================================================================================
#
#	System Administration CGI - Login Module
#	login.pl
#	---------------------------------------------------------------------------
#	2004.01.31 start
#
#============================================================================================================
package	MODULE;

use strict;
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	Constructor
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj);
	
	$obj = {
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($BASE, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	
	$Page = $BASE->Create($Sys, $Form);
	
	PrintLogin($Page, $Form);
	
	$BASE->PrintNoList('LOGIN', 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($host, $Security, $Mod);
	
	require './module/galadriel.pl';
	$host = GALADRIEL::GetRemoteHost();
	
	# ログイン情報を確認
	if ($pSys->{'USER'}) {
		require './mordor/sys.top.pl';
		$Mod = MODULE->new;
		$Form->Set('MODE_SUB', 'NOTICE');
		
		$pSys->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]", 'Login', 'TRUE');
		
		$Mod->DoPrint($Sys, $Form, $pSys);
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]", 'Login', 'FALSE');
		$Form->Set('FALSE', 1);
		$this->DoPrint($Sys, $Form, $pSys);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintLogin
{
	my ($Page, $Form) = @_;
	
$Page->Print(<<HTML);
  <center>
   <div align="center" class="LoginForm">
HTML
	
	if ($Form->Get('FALSE') == 1) {
		$Page->Print("    <div class=\"xExcuted\">The username or password used is incorrect!</div>\n");
	}
	
$Page->Print(<<HTML);
    <table align="center" border="0" style="margin:30px 0;">
     <tr>
      <td>Username</td><td><input type="text" name="UserName" style="width:200px"></td>
     </tr>
     <tr>
      <td>Password</td><td><input type="password" name="PassWord" style="width:200px"></td>
     </tr>
     <tr>
      <td colspan="2" align="center">
      <hr>
      <input type="submit" value="Log in">
      </td>
     </tr>
    </table>
    
    <div class="Sorce">
     <b>
     <font face="Arial" size="3" color="red">0ch+ Administration Page</font><br>
     <font face="Arial">Powered by 0ch/0ch+ script and 0ch/0ch+ modules 2002-2022</font>
     </b>
    </div>
    
   </div>
   
  </center>
  
  <!-- ▼こんなところに地下要塞(ry -->
   <input type="hidden" name="MODE" value="FUNC">
   <input type="hidden" name="MODE_SUB" value="">
  <!-- △こんなところに地下要塞(ry -->
  
HTML
	
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
