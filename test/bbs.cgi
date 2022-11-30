#!/usr/bin/perl
#============================================================================================================
#
#	書き込み用CGI
#
#============================================================================================================

use lib './perllib';

use strict;
#use warnings;
no warnings 'once';
##use CGI::Carp qw(fatalsToBrowser warningsToBrowser);


# CGIの実行結果を終了コードとする
exit(BBSCGI());

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	エラー番号
#
#------------------------------------------------------------------------------------------------------------
sub BBSCGI
{
	require './module/constant.pl';
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	my $CGI = {};
	my $err = $ZP::E_SUCCESS;
	
	$err = Initialize($CGI, $Page);
	# 初期化に成功したら書き込み処理を開始
	if ($err == $ZP::E_SUCCESS) {
		my $Sys = $CGI->{'SYS'};
		my $Form = $CGI->{'FORM'};
		my $Set = $CGI->{'SET'};
		my $Conv = $CGI->{'CONV'};
		my $Threads = $CGI->{'THREADS'};
		
		require './module/vara.pl';
		my $WriteAid = VARA->new;
		$WriteAid->Init($Sys, $Form, $Set, $Threads, $Conv);
		
		$err = $WriteAid->Write();
		# 書き込みに成功したら掲示板構成要素を更新する
		if ($err == $ZP::E_SUCCESS) {
			if (!$Sys->Equal('FASTMODE', 1)) {
				require './module/varda.pl';
				my $BBSAid = VARDA->new;
				
				$BBSAid->Init($Sys, $Set);
				$BBSAid->CreateIndex();
				$BBSAid->CreateIIndex();
				$BBSAid->CreateSubback();
			}
			PrintBBSJump($CGI, $Page);
		}
		else {
			PrintBBSError($CGI, $Page, $err);
		}
	}
	else {
		# スレッド作成画面表示
		if ($err == $ZP::E_PAGE_THREAD) {
			PrintBBSThreadCreate($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# cookie確認画面表示
		elsif ($err == $ZP::E_PAGE_COOKIE) {
			PrintBBSCookieConfirm($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# 携帯からのスレッド作成画面表示
		elsif ($err == $ZP::E_PAGE_THREADMOBILE) {
			PrintBBSMobileThreadCreate($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# エラー画面表示
		else {
			PrintBBSError($CGI, $Page, $err);
		}
	}
	
	# 結果の表示
	$Page->Flush('', 0, 0);
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi初期化
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($CGI, $Page) = @_;
	
	# 使用モジュールの初期化
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/radagast.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	require './module/baggins.pl';
	
	my $Sys = MELKOR->new;
	my $Conv = GALADRIEL->new;
	my $Set = ISILDUR->new;
	my $Cookie = RADAGAST->new;
	my $Threads = BILBO->new;
	
	# システム情報設定
	return $ZP::E_SYSTEM_ERROR if ($Sys->Init());
	
	my $Form = SAMWISE->new($Sys->Get('BBSGET'));
	
	%$CGI = (
		'SYS'		=> $Sys,
		'SET'		=> $Set,
		'COOKIE'	=> $Cookie,
		'CONV'		=> $Conv,
		'PAGE'		=> $Page,
		'FORM'		=> $Form,
		'THREADS'	=> $Threads,
	);
	
	# 夢が広がりんぐ
	$Sys->Set('MainCGI', $CGI);
	
	# form情報設定
	$Form->DecodeForm(1);
	
	# ホスト情報設定(DNS逆引き)
	#変数初期化チェックを挿入。
	if(!defined $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_HOST'} eq '') {
		$ENV{'REMOTE_HOST'} = $Conv->GetRemoteHost();
	}
	$Form->Set('HOST', $ENV{'REMOTE_HOST'});
	
	my $client = $Conv->GetClient();
	
	$Sys->Set('ENCODE', 'UTF-8');
	$Sys->Set('BBS', $Form->Get('bbs', ''));
	$Sys->Set('KEY', $Form->Get('key', ''));
	$Sys->Set('CLIENT', $client);
	$Sys->Set('AGENT', $Conv->GetAgentMode($client));
	$Sys->Set('KOYUU', $ENV{'REMOTE_HOST'});
	$Sys->Set('BBSPATH_ABS', $Conv->MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH')));
	$Sys->Set('BBS_ABS', $Conv->MakePath($Sys->Get('BBSPATH_ABS'), $Sys->Get('BBS')));
	$Sys->Set('BBS_REL', $Conv->MakePath($Sys->Get('BBSPATH'), $Sys->Get('BBS')));
	
	# 携帯の場合は機種情報を設定
	if ($client & $ZP::C_MOBILE_IDGET) {
		my $product = $Conv->GetProductInfo($client);
		
		if (!defined $product) {
			return $ZP::E_POST_NOPRODUCT;
		}
		
		$Sys->Set('KOYUU', $product);
	}
	
	# SETTING.TXTの読み込み
	if (!$Set->Load($Sys)) {
		return $ZP::E_POST_NOTEXISTBBS;
	}
	
	# 携帯からのスレッド作成フォーム表示
	# $S->Equal('AGENT', 'O') && 
	if ($Form->Equal('mb', 'on') && $Form->Equal('thread', 'on')) {
		return $ZP::E_PAGE_THREADMOBILE;
	}
	
	my $submax = $Set->Get('BBS_SUBJECT_MAX') || $Sys->Get('SUBMAX');
	$Sys->Set('SUBMAX', $submax);
	my $resmax = $Set->Get('BBS_RES_MAX') || $Sys->Get('RESMAX');
	$Sys->Set('RESMAX', $resmax);
	
	# form情報にkeyが存在したらレス書き込み
	if ($Form->IsExist('key'))	{ $Sys->Set('MODE', 2); }
	else						{ $Sys->Set('MODE', 1); }
	
	# スレッド作成モードでMESSAGEが無い：スレッド作成画面
	if ($Sys->Equal('MODE', 1)) {
		if (!$Form->IsExist('MESSAGE')) {
			return $ZP::E_PAGE_THREAD;
		}
		$Form->Set('key', int(time));
		$Sys->Set('KEY', $Form->Get('key'));
	}
	
	# cookieの存在チェック(PCのみ)
	if ($client & $ZP::C_PC) {
		if ($Set->Equal('SUBBBS_CGI_ON', 1)) {
			# 環境変数取得失敗
			if (!$Cookie->Init()) {
				return $ZP::E_PAGE_COOKIE;
			}
			
			# 名前欄cookie
			if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked') && !$Cookie->IsExist('NAME')) {
				return $ZP::E_PAGE_COOKIE;
			}
			# メール欄cookie
			if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked') && !$Cookie->IsExist('MAIL')) {
				return $ZP::E_PAGE_COOKIE;
			}
		}
	}
	
	# subjectの読み込み
	$Threads->Load($Sys);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiスレッド作成ページ表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSThreadCreate
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Form = $CGI->{'FORM'};
	my $Cookie = $CGI->{'COOKIE'};
	
	require './module/legolas.pl';
	my $Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	my $title = $Set->Get('BBS_TITLE');
	my $link = $Set->Get('BBS_TITLE_LINK');
	my $image = $Set->Get('BBS_TITLE_PICTURE');
	my $code = $Sys->Get('ENCODE');
	my $cgipath = $Sys->Get('CGIPATH');
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n");
	$Page->Print("<html lang=\"en\">\n");
	$Page->Print("<head>\n");
	$Page->Print(' <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">'."\n\n");
	$Caption->Print($Page, undef);
	$Page->Print(" <title>$title</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>タグ出力
	{
		my @work;
		$work[0] = $Set->Get('BBS_BG_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');
		$work[5] = $Set->Get('BBS_BG_PICTURE');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\" ");
		$Page->Print("background=\"$work[5]\">\n");
	}

	$Page->Print("<div align=\"center\">");
	# 看板画像表示あり
	if ($image ne '') {
		# 看板画像からのリンクあり
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$image\"></a><br>");
		}
		# 看板画像にリンクはなし
		else {
			$Page->Print("<img src=\"$image\" border=\"0\"><br>");
		}
	}
	$Page->Print("</div>");

	# ヘッダテーブルの表示
	$Caption->Load($Sys, 'HEAD');
	$Caption->Print($Page, $Set);
	
	# スレッド作成フォームの表示
	{
		my $tblCol = $Set->Get('BBS_MAKETHREAD_COLOR');
		my $name = $Cookie->Get('NAME', '', 'utf8');
		my $mail = $Cookie->Get('MAIL', '', 'utf8');
		my $bbs = $Form->Get('bbs');
		my $tm = int(time);
		my $ver = $Sys->Get('VERSION');
		
		$Page->Print(<<HTML);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" align="center">
 <tr>
  <td>
  <b>Create New Thread</b><br>
  <center>
  <form method="POST" action="./bbs.cgi?guid=ON">
  <input type="hidden" name="bbs" value="$bbs"><input type="hidden" name="time" value="$tm">
  <table border="0">
   <tr>
    <td align="left">
    Subject: <input type="text" name="subject" size="25"> <input type="submit" value="Post"><br>
    Name: <input type="text" name="FROM" size="19" value="$name" placeholder="Anonymous">
    E-mail<font size="1"> (Optional) </font> <input type="text" name="mail" size="19" value="$mail"><br>
    <textarea rows="5" cols="64" name="MESSAGE"></textarea>
    </td>
   </tr>
  </table>
  </form>
  </center>
  </td>
 </tr>
</table>

<p>
$ver
</p>
HTML
	}

	$Page->Print("\n</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiスレッド作成ページ(携帯)表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI	
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSMobileThreadCreate
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $title = $Set->Get('BBS_TITLE');
	my $bbs = $Sys->Get('BBS');
	my $tm = int(time);
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print("<html><head><title>$title</title></head><!--nobanner-->");
	$Page->Print("\n<body><form action=\"./bbs.cgi?guid=ON\" method=\"POST\"><center>$title<hr>");
	
	$Banner->Print($Page, 100, 2, 1);
	
	$Page->Print("</center>\n");
	$Page->Print("Title<br><input type=text name=subject><br>");
	$Page->Print("Name<br><input type=text name=FROM><br>");
	$Page->Print("E-mail<br><input type=text name=mail><br>");
	$Page->Print("<textarea name=MESSAGE></textarea><br>");
	$Page->Print("<input type=hidden name=bbs value=$bbs>");
	$Page->Print("<input type=hidden name=time value=$tm>");
	$Page->Print("<input type=hidden name=mb value=on>");
	$Page->Print("<input type=submit value=\"Thread Creation\">");
	$Page->Print("</form></body></html>");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiクッキー確認ページ表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI	
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSCookieConfirm
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Form = $CGI->{'FORM'};
	my $Set = $CGI->{'SET'};
	my $Cookie = $CGI->{'COOKIE'};
	
	my $sanitize = sub {
		$_ = shift;
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		s/"/&#34;/g;
		return $_;
	};
	my $code = $Sys->Get('ENCODE');
	my $bbs = &$sanitize($Form->Get('bbs'));
	my $tm = int(time);
	my $name = &$sanitize($Form->Get('FROM'));
	my $mail = &$sanitize($Form->Get('mail'));
	my $msg = &$sanitize($Form->Get('MESSAGE'));
	my $subject = &$sanitize($Form->Get('subject'));
	my $key = &$sanitize($Form->Get('key'));
	
	# cookie情報の出力
	$Cookie->Set('NAME', $name, 'utf8')	if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
	$Cookie->Set('MAIL', $mail, 'utf8')	if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
	$Cookie->Out($Page, $Set->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<!-- 2ch_X:cookie -->
<head>

 <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

 <title>■ Post Confirmation ■</title>

</head>
<!--nobanner-->
HTML
	
	# <body>タグ出力
	{
		my @work;
		$work[0] = $Set->Get('BBS_THREAD_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n");
	}
	
	$Page->Print(<<HTML);
<font size="4" color="#FF0000"><b>書きこみ＆クッキー確認</b></font>
<blockquote style="margin-top:4em;">
 Name: $name<br>
 E-mail: $mail<br>
 Message: <br>
 $msg<br>
</blockquote>

<div style="font-weight:bold;">
Post Confirmation<br>
・You agree that that content is the responsibility of the poster.<br>
・You agree not to advertise.<br>
・You agree that by posting, you give operators a royalty-free license to copy, save, quote, and repost the posted content.<br>
I also agree not to exercise any moral rights against the BBS operator.<br>
・The contributor agrees not to grant any license to use the copyrighted material to any third party designated by the BBS operator.<br>
</div>

<form method="POST" action="./bbs.cgi?guid=ON">
HTML
	
	$msg =~ s/<br>/\n/g;
	
	$Page->HTMLInput('hidden', 'subject', $subject);
	$Page->HTMLInput('hidden', 'FROM', $name);
	$Page->HTMLInput('hidden', 'mail', $mail);
	$Page->HTMLInput('hidden', 'MESSAGE', $msg);
	$Page->HTMLInput('hidden', 'bbs', $bbs);
	$Page->HTMLInput('hidden', 'time', $tm);
	
	# レス書き込みモードの場合はkeyを設定する
	if ($Sys->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $key);
	}
	
	$Page->Print(<<HTML);
<input type="submit" value="I agree to all above."><br>
</form>

<p>
If you want to change it, please use the back button to go back and rewrite it.
</p>

<p>
Currently, we are preventing writing without setting a cookie to prevent vandalism.<br>
<font size="2">(If you set a cookie, this screen will not appear.)</font><br>
</p>

</body>
</html>
HTML
}


#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiジャンプページ表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSJump
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Form = $CGI->{'FORM'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Cookie = $CGI->{'COOKIE'};
	
	# 携帯用表示
	if ($Form->Equal('mb', 'on') || ($Sys->Get('CLIENT') & $ZP::C_MOBILEBROWSER) ) {
		my $bbsPath = $Conv->MakePath($Sys->Get('CGIPATH').'/r.cgi/'.$Form->Get('bbs').'/'.$Form->Get('key').'/l10');
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print('<!--nobanner--><html><body>書き込み完了です<br>');
		$Page->Print("<a href=\"$bbsPath\">こちら</a>");
		$Page->Print("から掲示板へ戻ってください。\n");
	}
	# PC用表示
	else {
		my $bbsPath = $Conv->MakePath($Sys->Get('BBS_REL'));
		my $name = $Form->Get('NAME', '');
		my $mail = $Form->Get('MAIL', '');
		
		$Cookie->Set('NAME', $name, 'utf8')	if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
		$Cookie->Set('MAIL', $mail, 'utf8')	if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
		$Cookie->Out($Page, $Set->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
		
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print(<<HTML);
<html>
<head>
	<title>Posted!</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Refresh" content="5;URL=$bbsPath/">
</head>
<!--nobanner-->
<body>
Post successful!<br>
<br>
Redirecting now...<br>
<br>
<br>
<br>
<br>
<hr>
HTML
	
	}
	# 告知欄表示(表示させたくない場合はコメントアウトか条件を0に)
	if (0) {
		require './module/denethor.pl';
		my $Banner = DENETHOR->new;
		$Banner->Load($Sys);
		$Banner->Print($Page, 100, 0, $Sys->Get('AGENT'));
	}
	$Page->Print("\n</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiエラーページ表示
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$err
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSError
{
	my ($CGI, $Page, $err) = @_;
	
	require './module/orald.pl';
	my $Error = ORALD->new;
	$Error->Load($CGI->{'SYS'});
	
	$Error->Print($CGI, $Page, $err, $CGI->{'SYS'}->Get('AGENT'));
}

