#============================================================================================================
#
#	管理CGIベースモジュール 
#	sauron.pl
#	---------------------------------------------------------------------------
#	2003.10.12 start
#
#============================================================================================================
package	SAURON;

use strict;
#use warnings;

require './module/thorin.pl';

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------------------------------------------------
#	引　数：なし
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj, @MnuStr, @MnuUrl);
	
	$obj = {
		'SYS'		=> undef,														# MELKOR保持
		'FORM'		=> undef,														# SAMWISE保持
		'INN'		=> undef,														# THORIN保持
		'MNUSTR'	=> \@MnuStr,													# 機能リスト文字列
		'MNUURL'	=> \@MnuUrl,													# 機能リストURL
		'MNUNUM'	=> 0															# 機能リスト数
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	オブジェクト生成 - Create
#	-------------------------------------------------------------------------------------
#	引　数：$M : MELKORモジュール
#			$S : SAMWISEモジュール
#	戻り値：THORINモジュール
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my $this = shift;
	my ($Sys, $Form) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'INN'}		= THORIN->new;
	$this->{'MNUNUM'}	= 0;
	
	return $this->{'INN'};
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューの設定 - SetMenu
#	-------------------------------------------------------------------------------------
#	引　数：$str : 表示文字列
#			$url : ジャンプURL
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenu
{
	my $this = shift;
	my ($str, $url) = @_;
	
	push @{$this->{'MNUSTR'}}, $str;
	push @{$this->{'MNUURL'}}, $url;
	
	$this->{'MNUNUM'} ++;
}

#------------------------------------------------------------------------------------------------------------
#
#	ページ出力 - Print
#	-------------------------------------------------------------------------------------
#	引　数：$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($ttl, $mode) = @_;
	my ($Tad, $Tin, $TPlus);
	
	$Tad	= THORIN->new;
	$Tin	= $this->{'INN'};
	
	PrintHTML($Tad, $ttl);																# HTMLヘッダ出力
	PrintCSS($Tad, $this->{'SYS'});														# CSS出力
	PrintHead($Tad, $ttl, $mode);														# ヘッダ出力
	PrintList($Tad, $this->{'MNUNUM'}, $this->{'MNUSTR'}, $this->{'MNUURL'});			# 機能リスト出力
	PrintInner($Tad, $Tin, $ttl);														# 機能内容出力
	PrintCommonInfo($Tad, $this->{'FORM'});
	PrintFoot($Tad, $this->{'FORM'}->Get('UserName'), $this->{'SYS'}->Get('VERSION'),
						$this->{'SYS'}->Get('ADMIN')->{'NEWRELEASE'}->Get('Update'));	# フッタ出力
	
	$Tad->Flush(0, 0, '');																# 画面出力
}

#------------------------------------------------------------------------------------------------------------
#
#	ページ出力(メニューリストなし) - PrintNoList
#	-------------------------------------------------------------------------------------
#	引　数：$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoList
{
	my $this = shift;
	my ($ttl, $mode) = @_;
	my ($Tad, $Tin);
	
	$Tad = THORIN->new;
	$Tin = $this->{'INN'};
	
	PrintHTML($Tad, $ttl);															# HTMLヘッダ出力
	PrintCSS($Tad, $this->{'SYS'}, $ttl);											# CSS出力
	PrintHead($Tad, $ttl, $mode);													# ヘッダ出力
	PrintInner($Tad, $Tin, $ttl);													# 機能内容出力
	PrintFoot($Tad, 'NONE', $this->{'SYS'}->Get('VERSION'));						# フッタ出力
	
	$Tad->Flush(0, 0, '');															# 画面出力
}

#------------------------------------------------------------------------------------------------------------
#
#	HTMLヘッダ出力 - PrintHTML
#	-------------------------------------------
#	引　数：$T   : THORINモジュール
#			$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintHTML
{
	my ($Page, $ttl) = @_;
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en-us">
<head>
 
 <title>ZeroChEN Management - [ $ttl ]</title>
 
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	スタイルシート出力 - PrintCSS
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCSS
{
	my ($Page, $Sys, $ttl) = @_;
	my ($data);
	
	$data = $Sys->Get('DATA');
	
$Page->Print(<<HTML);
 <meta http-equiv=Content-Type content="text/html;charset=UTF-8">
 
 <meta http-equiv="Content-Script-Type" content="text/javascript">
 <meta http-equiv="Content-Style-Type" content="text/css">
 
 <meta name="robots" content="noindex,nofollow">
 
 <link rel="stylesheet" href=".$data/admin.css" type="text/css">
 <script language="javascript" src=".$data/admin.js"></script>
 
</head>
<!--nobanner-->
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	ページヘッダ出力 - PrintHead
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#			$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my ($Page, $ttl, $mode) = @_;
	my ($common);
	
	$common = '<a href="javascript:DoSubmit';
	
$Page->Print(<<HTML);
<body>

<form name="ADMIN" action="./admin.cgi" method="POST"@{[$mode ? ' onsubmit="return Submitted();"' : '']}>

<div class="MainMenu" align="right">
HTML
	
	# システム管理メニュー
	if ($mode == 1) {
		
$Page->Print(<<HTML);
  <a href="javascript:DoSubmit('sys.top','DISP','NOTICE');">Top</a> |
  <a href="javascript:DoSubmit('sys.bbs','DISP','LIST');">Board</a> |
  <a href="javascript:DoSubmit('sys.user','DISP','LIST');">User</a> |
  <a href="javascript:DoSubmit('sys.cap','DISP','LIST');">Cap</a> |
  <a href="javascript:DoSubmit('sys.capg','DISP','LIST');">Common cap group</a> |
  <a href="javascript:DoSubmit('sys.setting','DISP','INFO');">System Settings</a> |
  <a href="javascript:DoSubmit('sys.edit','DISP','BANNER_PC');">Various edits</a> |
HTML
		
	}
	# 掲示板管理メニュー
	elsif ($mode == 2) {
		
$Page->Print(<<HTML);
  <a href="javascript:DoSubmit('bbs.thread','DISP','LIST');">Thread</a> |
  <a href="javascript:DoSubmit('bbs.pool','DISP','LIST');">Pool</a> |
  <a href="javascript:DoSubmit('bbs.kako','DISP','LIST');">Past log</a> |
  <a href="javascript:DoSubmit('bbs.setting','DISP','SETINFO');">Board settings</a> |
  <a href="javascript:DoSubmit('bbs.edit','DISP','HEAD');">Various edits</a> |
  <a href="javascript:DoSubmit('bbs.user','DISP','LIST');">Admin Group</a> |
  <a href="javascript:DoSubmit('bbs.cap','DISP','LIST');">Cap group</a> |
  <a href="javascript:DoSubmit('bbs.log','DISP','INFO');">View log</a> |
HTML
		
	}
	# スレッド管理メニュー
	elsif ($mode == 3) {
		
$Page->Print(<<HTML);
  <a href="javascript:DoSubmit('thread.res','DISP','LIST');">List of responses</a> |
  <a href="javascript:DoSubmit('thread.del','DISP','LIST');">Remove list</a> |
HTML
		
	}
	
$Page->Print(<<HTML);
 <a href="javascript:DoSubmit('login','','');">Log out</a>
</div>
 
<div class="MainHead" align="right">0ch+ BBS System Manager</div>

<table cellspacing="0" width="100%" height="400">
 <tr>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	機能リスト出力 - PrintList
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#			$str : 機能タイトル配列
#			$url : 機能URL配列
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintList
{
	my ($Page, $n, $str, $url) = @_;
	my ($i, $strURL, $strTXT);
	
$Page->Print(<<HTML);
  <td valign="top" class="Content">
  <table width="95%" cellspacing="0">
   <tr>
    <td class="FunctionList">
HTML
	
	for ($i = 0 ; $i < $n ; $i++) {
		$strURL = $$url[$i];
		$strTXT = $$str[$i];
		if ($strURL eq '') {
			$Page->Print("    <font color=\"gray\">$strTXT</font>\n");
			if ($strTXT ne '<hr>') {
				$Page->Print('    <br>'."\n");
			}
		}
		else {
			$Page->Print("    <a href=\"javascript:DoSubmit($$url[$i]);\">");
			$Page->Print("$$str[$i]</a><br>\n");
		}
	}
	
$Page->Print(<<HTML);
    </td>
   </tr>
  </table>
  </td>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	機能内容出力 - PrintInner
#	-------------------------------------------
#	引　数：$Page1 : THORINモジュール(MAIN)
#			$Page2 : THORINモジュール(内容)
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintInner
{
	my ($Page1, $Page2, $ttl) = @_;
	
$Page1->Print(<<HTML);
  <td width="80%" valign="top" class="Function">
  <div class="FuncTitle">$ttl</div>
HTML
	
	$Page1->Merge($Page2);
	
	$Page1->Print("  </td>\n");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	共通情報出力 - PrintCommonInfo
#	-------------------------------------------
#	引　数：$Sys   : 
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCommonInfo
{
	my ($Page, $Form) = @_;
	
	my $user = $Form->Get('UserName', '');
	my $sid = $Form->Get('SessionID', '');
	
$Page->Print(<<HTML);
  <!-- ▼こんなところに地下要塞(ry -->
   <input type="hidden" name="MODULE" value="">
   <input type="hidden" name="MODE" value="">
   <input type="hidden" name="MODE_SUB" value="">
   <input type="hidden" name="UserName" value="$user">
   <input type="hidden" name="SessionID" value="$sid">
  <!-- △こんなところに地下要塞(ry -->
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	フッタ出力 - PrintFoot
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my ($Page, $user, $ver, $nverflag) = @_;
	
$Page->Print(<<HTML);
 </tr>
</table>

<div class="MainFoot">
 Copyright 2001 - 2022 0ch+ BBS : Loggin User - <b>$user</b><br>
 Build Version:<b>$ver</b>@{[$nverflag ? " (New Version is Available.)" : '']}
</div>

</form>

</body>
</html>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	完了画面の出力
#	-------------------------------------------------------------------------------------
#	@param	$processName	処理名
#	@param	$pLog	処理ログ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintComplete
{
	my $this = shift;
	my ($processName, $pLog) = @_;
	my ($Page, $text);
	
	$Page = $this->{'INN'};
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="oExcuted">
     $processName completed successfully.
    </div>
   
    <div class="LogExport">Export Log</div>
    <hr>
    <blockquote class="LogExport">
HTML
	
	# ログの表示
	foreach $text (@$pLog) {
		$Page->Print("     $text<br>\n");
	}
	
$Page->Print(<<HTML);
    </blockquote>
    <hr>
    </td>
   </tr>
  </table>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	エラーの表示
#	-------------------------------------------------------------------------------------
#	@param	$pLog	ログ用
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintError
{
	my $this = shift;
	my ($pLog) = @_;
	my ($Page, $ecode);
	
	$Page = $this->{'INN'};
	
	# エラーコードの抽出
	$ecode = pop @$pLog;
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="xExcuted">
HTML
	
	if ($ecode == 1000) {
	$Page->Print(" ERROR: $ecode - You do not have permission to process this function.\n");
	}
	elsif ($ecode == 1001) {
	$Page->Print(" ERROR:$ecode - required field is blank.\n");
	}
	elsif ($ecode == 1002) {
	$Page->Print(" ERROR: $ecode - Illegal characters used in settings.\n");
	}
	elsif ($ecode == 2000) {
	$Page->Print(" ERROR:$ecode - Failed to create bulletin board directory.<br>\n");
	$Page->Print(" Please check your permissions or if a bulletin board with the same name has already been created.\n");
	}
	elsif ($ecode == 2001) {
	$Page->Print(" ERROR: $ecode - Failed to generate SETTING.TXT.\n");
	}
	elsif ($ecode == 2002) {
	$Page->Print(" ERROR:$ecode - Failed to generate message board component.\n");
	}
	elsif ($ecode == 2003) {
	$Page->Print(" ERROR:$ecode - Failed to generate initial log information.\n");
	}
	elsif ($ecode == 2004) {
	$Page->Print(" ERROR:$ecode - Failed to update bulletin board information.\n");
	}
	else {
	$Page->Print(" ERROR:$ecode - An unknown error occurred.\n");
	}
	
$Page->Print(<<HTML);
    </div>
    
HTML

	# エラーログがあれば出力する
	if (@$pLog) {
		$Page->Print('<hr>');
		$Page->Print("    <blockquote>");
		foreach (@$pLog) {
			$Page->Print("    $_<br>\n");
		}
		$Page->Print("    </blockquote>");
		$Page->Print('<hr>');
	}
	
$Page->Print(<<HTML);
    </td>
   </tr>
  </table>
HTML
	
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;
