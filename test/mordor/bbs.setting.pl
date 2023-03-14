#============================================================================================================
#
#	掲示板管理 - 掲示板設定 モジュール
#	bbs.setting.pl
#	---------------------------------------------------------------------------
#	2004.06.01 start
#
#============================================================================================================
package	MODULE;

use strict;
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj, @LOG);
	
	$obj = {
		'LOG'	=> \@LOG
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
	my ($subMode, $BASE, $BBS, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	$BBS = $pSys->{'AD_BBS'};
	
	# 掲示板情報の読み込みとグループ設定
	if (! defined $BBS) {
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	}
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE, $pSys, $Sys->Get('BBS'));
	
	if ($subMode eq 'SETINFO') {													# 設定情報画面
		PrintSettingInfo($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETBASE') {													# 基本設定画面
		PrintBaseSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETCOLOR') {												# カラー設定画面
		PrintColorSetting($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'SETCOLORC') {												# カラー設定確認画面
		PrintColorSetting($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'SETLIMIT') {												# 制限設定画面
		PrintLimitSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETOTHER') {												# その他設定画面
		PrintOtherSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETIMPORT') {												# インポート画面
		PrintSettingImport($Page, $Sys, $Form, $BBS);
	}
	elsif ($subMode eq 'COMPLETE') {												# 設定完了画面
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('掲示板設定処理', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# 設定失敗画面
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	# 掲示板情報を設定
	$Page->HTMLInput('hidden', 'TARGET_BBS', $Form->Get('TARGET_BBS'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME', $Form->Get('TARGET_BBS')), 2);
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
	my ($subMode, $err, $BBS);
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	# 管理情報を登録
	$BBS->Load($Sys);
	$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	$Sys->Set('ADMIN', $pSys);
	$pSys->{'SECINFO'}->SetGroupInfo($Sys->Get('BBS'));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 9999;
	
	if ($subMode eq 'SETBASE') {													# 基本設定
		$err = FunctionBaseSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETCOLOR') {												# カラー設定
		$err = FunctionColorSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETLIMIT') {												# 制限設定
		$err = FunctionLimitSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETOTHER') {												# その他設定
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETORIGIN') {												# オリジナル設定
		$err = FunctionOriginalSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETIMPORT') {												# インポート
		$err = FunctionSettingImport($Sys, $Form, $this->{'LOG'}, $BBS);
	}
	
	# 処理結果表示
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"THREAD($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"THREAD($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$pSys->{'AD_BBS'} = $BBS;
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys, $bbs) = @_;
	
	$Base->SetMenu('Setup Information', "'bbs.setting','DISP','SETINFO'");
	
	# 管理グループ設定権限のみ
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, $ZP::AUTH_BBSSETTING, $bbs)){
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('Base', "'bbs.setting','DISP','SETBASE'");
		$Base->SetMenu('Colors/Theming', "'bbs.setting','DISP','SETCOLOR'");
		$Base->SetMenu('Limits', "'bbs.setting','DISP','SETLIMIT'");
		$Base->SetMenu('Other', "'bbs.setting','DISP','SETOTHER'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('Import Settings', "'bbs.setting','DISP','SETIMPORT'");
	}
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('Back to System Management', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	設定情報画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSettingInfo
{
	my ($Page, $SYS, $Form) = @_;
	my ($Setting, @settingKeys, $key, $val, $keyNum, $i);
	
	$SYS->Set('_TITLE', 'BBS Setting Information');
	
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($SYS);
	
	$Setting->GetKeySet(\@settingKeys);
	$keyNum = @settingKeys;
	push @settingKeys, '';
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	for ($i = 0 ; $i < ($keyNum / 2) ; $i++) {
		$key = $settingKeys[$i * 2];
		$val = $Setting->Get($key, '');
		$Page->Print("<tr><td class=\"DetailTitle\">$key</td><td>$val</td>");
		$key = $settingKeys[$i * 2 + 1];
		$val = $Setting->Get($key, '');
		$Page->Print("<td class=\"DetailTitle\">$key</td><td>$val</td></tr>\n");
	}
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	基本設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBaseSetting
{
	my ($Page, $Sys, $Form) = @_;
	
	$Sys->Set('_TITLE', 'BBS Base Setting');
	
	require './module/isildur.pl';
	my $Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	my $setSubTitle		= $Setting->Get('BBS_SUBTITLE');
	my $setKanban		= $Setting->Get('BBS_TITLE_PICTURE');
	my $setKnabanLink	= $Setting->Get('BBS_TITLE_LINK');
	my $setBackPict		= $Setting->Get('BBS_BG_PICTURE');
	my $setNoName		= $Setting->Get('BBS_NONAME_NAME');
	my $setAbone		= $Setting->Get('BBS_DELETE_NAME');
	my $setCookiePath	= $Setting->Get('BBS_COOKIEPATH');
	my $setRefCushion	= $Setting->Get('BBS_REFERER_CUSHION');
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>Enter each setting value and press Submit.</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Subtitle</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_SUBTITLE value=\"$setSubTitle\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Index logo image</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_TITLE_PICTURE value=\"$setKanban\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Index logo link</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_TITLE_LINK value=\"$setKnabanLink\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Index background image</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_BG_PICTURE value=\"$setBackPict\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Anonymous name</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_NONAME_NAME value=\"$setNoName\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Delete name</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_DELETE_NAME value=\"$setAbone\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Cookie storage path</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_COOKIEPATH value=\"$setCookiePath\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Referral cushion</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_REFERER_CUSHION value=\"$setRefCushion\"></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"Submit\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETBASE');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	カラー設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@param	$flg	モード(0:表示 1:確認)
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintColorSetting
{
	my ($Page, $SYS, $Form, $flg) = @_;
	my ($Setting);
	my ($setIndexTitle, $setThreadTitle, $setIndexBG, $setThreadBG, $setCreateBG);
	my ($setMenuBG, $setText, $setLink, $setLinkA, $setLinkV, $setName, $setCap);
	
	$SYS->Set('_TITLE', 'BBS Color Setting');
	
	# SETTING.TXTから値を取得
	if ($flg == 0) {
		require './module/isildur.pl';
		$Setting = ISILDUR->new;
		$Setting->Load($SYS);
	}
	# フォーム情報から値を取得
	else {
		$Setting = $Form;
	}
	
	# 設定値を取得
	$setIndexTitle	= $Setting->Get('BBS_TITLE_COLOR');
	$setThreadTitle	= $Setting->Get('BBS_SUBJECT_COLOR');
	$setIndexBG		= $Setting->Get('BBS_BG_COLOR');
	$setThreadBG	= $Setting->Get('BBS_THREAD_COLOR');
	$setCreateBG	= $Setting->Get('BBS_MAKETHREAD_COLOR');
	$setMenuBG		= $Setting->Get('BBS_MENU_COLOR');
	$setText		= $Setting->Get('BBS_TEXT_COLOR');
	$setLink		= $Setting->Get('BBS_LINK_COLOR');
	$setLinkA		= $Setting->Get('BBS_ALINK_COLOR');
	$setLinkV		= $Setting->Get('BBS_VLINK_COLOR');
	$setName		= $Setting->Get('BBS_NAME_COLOR');
	$setCap			= $Setting->Get('BBS_CAP_COLOR');
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=6>Enter each setting color then press Save.</td></tr>");
	$Page->Print("<tr><td colspan=6><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">indexBackgroundColor</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_BG_COLOR value=\"$setIndexBG\">");
	$Page->Print("</td><td bgcolor=$setIndexBG></td>");
	$Page->Print("<td class=\"DetailTitle\">Text color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_TEXT_COLOR value=\"$setText\">");
	$Page->Print("</td><td><font color=$setText>Text</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">indexMenu background color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MENU_COLOR value=\"$setMenuBG\">");
	$Page->Print("</td><td bgcolor=$setMenuBG></td>");
	$Page->Print("<td class=\"DetailTitle\">Name Color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_NAME_COLOR value=\"$setName\">");
	$Page->Print("</td><td><font color=$setName>Name</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Thread creation background color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MAKETHREAD_COLOR value=\"$setCreateBG\">");
	$Page->Print("</td><td bgcolor=$setCreateBG></td>");
	$Page->Print("<td class=\"DetailTitle\">Link Color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_LINK_COLOR value=\"$setLink\">");
	$Page->Print("</td><td><font color=$setLink>Link</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Thread background color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_THREAD_COLOR value=\"$setThreadBG\">");
	$Page->Print("</td><td bgcolor=$setThreadBG></td>");
	$Page->Print("<td class=\"DetailTitle\">Link color (when anchored)</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_ALINK_COLOR value=\"$setLinkA\">");
	$Page->Print("</td><td><font color=$setLinkA>link (anchor)</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">index title color</td><td>");
	$Page->Print("</td><td><font color=$setIndexTitle>index title</font></td>");
	$Page->Print("<td class=\"DetailTitle\">Link Color (Visit)</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_VLINK_COLOR value=\"$setLinkV\">");
	$Page->Print("</td><td><font color=$setLinkV>Link (visited)</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Thread Title Color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_SUBJECT_COLOR value=\"$setThreadTitle\">");
	$Page->Print("</td><td><font color=$setThreadTitle>Thread Title</font></td>");
	$Page->Print("<td class=\"DetailTitle\">Cap color</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_CAP_COLOR value=\"$setCap\">");
	$Page->Print("</td><td><font color=$setName><font color=$setCap>Name</font></font></td></tr>\n");
	$Page->Print("<tr><td colspan=6><hr></td></tr>");
	
	# スレッドプレビューの表示
	if (1) {
		$Page->Print("<tr><td class=\"DetailTitle\" colspan=3>index preview</td>");
		$Page->Print("<td class=\"DetailTitle\" colspan=3>Thread Preview</td></tr>");
		$Page->Print("<tr><td colspan=3 bgcolor=$setIndexBG>");
		$Page->Print("<center><font color=$setIndexTitle>index title</font><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setMenuBG border><td>Header</		td></table><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setMenuBG border><td>Menu</td></table><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setThreadBG border><td>");
		$Page->Print("<font color=$setThreadTitle>Thread Title</font><br><br>");
		$Page->Print("<font color=$setText>Text</font><br></td></table><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setCreateBG border><td>Create thread</td>");
		$Page->Print("</table><br></center></td>");
		$Page->Print("<td colspan=3 bgcolor=$setThreadBG valign=top><font color=$setThreadTitle>");
		$Page->Print("Thread Title</font><br><br>1 <font color=$setName>Name@<font color=$setCap>Name</font></font><br>" );
		$Page->Print("<font color=$setLink><u>http://---</u></font><br>");
		$Page->Print("<font color=$setLinkV><u>http://---</u></font><br>");
		$Page->Print("</td></tr>");
		$Page->Print("<tr><td colspan=6><hr></td></tr>");
	}
	$Page->Print("<tr><td colspan=6 align=left>");
	$Page->Print("<input type=button value=\"　Save　\" onclick=\"DoSubmit");
	$Page->Print("('bbs.setting','FUNC','SETCOLOR');\"> ");
	$Page->Print("<input type=button value=\"　Preview　\" onclick=\"DoSubmit");
	$Page->Print("('bbs.setting','DISP','SETCOLORC');\">");
	$Page->Print("</td></tr></table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	制限設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintLimitSetting
{
	my ($Page, $Sys, $Form) = @_;
	
	$Sys->Set('_TITLE', 'BBS Limitter Setting');
	
	require './module/isildur.pl';
	my $Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	# 設定値を取得
	my $setResMax		= $Setting->Get('BBS_RES_MAX');
	my $setSubMax		= $Setting->Get('BBS_SUBJECT_MAX');		# 最大スレッド数
	my $setSubjectMax	= $Setting->Get('BBS_SUBJECT_COUNT');	# タイトル最大バイト数
	my $setNameMax		= $Setting->Get('BBS_NAME_COUNT');
	my $setMailMax		= $Setting->Get('BBS_MAIL_COUNT');
	my $setContMax		= $Setting->Get('BBS_MESSAGE_COUNT');
	my $setLineMax		= $Setting->Get('BBS_LINE_NUMBER') *2;
	my $setWriteMax		= $Setting->Get('timeclose')||0;
	my $setContinueMax	= $Setting->Get('timecount')||0;
	my $setNoName		= $Setting->Get('NANASHI_CHECK');
	my $setProxy		= $Setting->Get('BBS_PROXY_CHECK');
	my $setOverSea		= $Setting->Get('BBS_JP_CHECK');
	my $setTomato		= $Setting->Get('BBS_RAWIP_CHECK');
	
	my $setDatMax		= $Setting->Get('BBS_DATMAX');
	my $setLineLength	= $Setting->Get('BBS_COLUMN_NUMBER');
	my $setReadOnly		= $Setting->Get('BBS_READONLY');
	my $setCapOnly		= $Setting->Get('BBS_THREADCAPONLY');
	my $setThreadMb		= $Setting->Get('BBS_THREADMOBILE');
	my $setSambaTime	= $Setting->Get('BBS_SAMBATIME');
	my $setHoushiTime	= $Setting->Get('BBS_HOUSHITIME');
	my $setTateClose	= $Setting->Get('BBS_THREAD_TATESUGI');
	my $setTateCount2	= $Setting->Get('BBS_TATESUGI_COUNT2');
	my $setTateHour		= $Setting->Get('BBS_TATESUGI_HOUR');
	my $setTateCount	= $Setting->Get('BBS_TATESUGI_COUNT');
	
	my $selROnone		= ($setReadOnly eq 'none' ? 'selected' : '');
	my $selROcaps		= ($setReadOnly eq 'caps' ? 'selected' : '');
	my $selROon			= ($setReadOnly eq 'on' ? 'selected' : '');
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=4>Enter each setting value and press Submit.</td></tr>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">Max title length</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_SUBJECT_COUNT value=\"$setSubjectMax\"></td>");
	$Page->Print("<td class=\"DetailTitle\">Max e-mail length</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MAIL_COUNT value=\"$setMailMax\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Max name length</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_NAME_COUNT value=\"$setNameMax\"></td>");
	$Page->Print("<td class=\"DetailTitle\">Maximum Message Length</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MESSAGE_COUNT value=\"$setContMax\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Maximum number of characters per line</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_COLUMN_NUMBER value=\"$setLineLength\"></td>");
	$Page->Print("<td class=\"DetailTitle\">dat file maximum size (KB)</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_DATMAX value=\"$setDatMax\"></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Max amount of lines</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_LINE_NUMBER value=\"$setLineMax\"></td>");
	$Page->Print("<td class=\"DetailTitle\">Max Threads (".$Sys->Get('SUBMAX').")</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_SUBJECT_MAX value=\"$setSubMax\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Require names</td><td>");
	$Page->Print("<input type=checkbox name=NANASHI_CHECK $setNoName value=on>Enable</td>");
	$Page->Print("<td class=\"DetailTitle\">Maximum Post Count (".$Sys->Get('RESMAX').")</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_RES_MAX value=\"$setResMax\"></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">Read Only</td><td><select name=BBS_READONLY>");
	$Page->Print("<option value=on $selROon>Read Only");
	$Page->Print("<option value=caps $selROcaps>Capcodes Only");
	$Page->Print("<option value=none $selROnone>Writable");
	$Page->Print("</select></td>");
	$Page->Print("<td class=\"DetailTitle\">DNSBL check</td><td>");
	$Page->Print("<input type=checkbox name=BBS_PROXY_CHECK $setProxy value=on>Enable</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Require all users have a capcode to make new threads</td><td>");
	$Page->Print("<input type=checkbox name=BBS_THREADCAPONLY $setCapOnly value=on>Enable\</td>");
	$Page->Print("<td class=\"DetailTitle\">Block non-Japanese IPs?</td><td>");
	$Page->Print("<input type=checkbox name=BBS_JP_CHECK $setOverSea value=on>Enable</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Thread Creation Limit (Mobile)</td><td>");
	$Page->Print("<input type=checkbox name=BBS_THREADMOBILE $setThreadMb value=on>Allow from mobileﾂ</td>");
	$Page->Print("</tr>");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>Flood Control</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("Of the <input type=text size=5 name=timecount value=\"$setContinueMax\" style=\"text-align: right\">most recent posts, ");
	$Page->Print("a single IP address can be up to <input type=text size=5 name=timeclose value=\"$setWriteMax\" style=\"text-align: right\"> of the posts. (Set the second number higher than the first to disable)");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>Samba Regulation</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("A person that tries to post more than once in <input type=text size=5 name=BBS_SAMBATIME value=\"$setSambaTime\" style=\"text-align: right\"> seconds (0 to disable) will be blocked from posting. (blank=".$Sys->Get('DEFSAMBA').")<br>");
	$Page->Print("If a person tries to post too many times without waiting, then temporarily block the user from posting for <input type=text size=5 name=BBS_HOUSHITIME value=\"$setHoushiTime\" style=\"text-align: right\"> minutes. (blank=".$Sys->Get('DEFHOUSHI').")");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>Thread overload restriction (time-independent)</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("A single user can be the OP of the last <input type=text size=5 name=BBS_THREAD_TATESUGI value=\"$setTateClose\" style=\"text-align: right\">threads (0 to disable),");
	$Page->Print("一人が<input type=text size=5 name=BBS_TATESUGI_COUNT2 value=\"$setTateCount2\" style=\"text-align: right\">スレッドまで立てられる");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>Thread overload restriction (time dependent)</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("Within <input type=text size=5 name=BBS_TATESUGI_HOUR value=\"$setTateHour\" style=\"text-align: right\">");
	$Page->Print(" hours (0 to disable), up to <input type=text size=5 name=BBS_TATESUGI_COUNT value=\"$setTateCount\" style=\"text-align: right\"> new threads can be made.");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("<tr><td colspan=4 align=left><input type=button value=\"　Save　\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETLIMIT');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintOtherSetting
{
	my ($Page, $Sys, $Form) = @_;
	
	$Sys->Set('_TITLE', 'BBS Other Setting');
	
	require './module/isildur.pl';
	my $Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	my $setIPSave		= $Setting->Get('BBS_SLIP');
	my $setIDForce		= $Setting->Get('BBS_FORCE_ID');
	my $setIDNone		= $Setting->Get('BBS_NO_ID');
	my $setIDHost		= $Setting->Get('BBS_DISP_IP');
	my $setIDDisp		= ($setIDForce eq '' && $setIDNone eq '' ? 'checked' : '');
	my $selIDforce		= ($setIDForce eq 'checked' ? 'selected' : '');
	my $selIDnone		= ($setIDNone eq 'checked' ? 'selected' : '');
	my $selIDdisp		= ($setIDDisp eq 'checked' ? 'selected' : '');
	my $selIDhost		= ($setIDHost eq 'checked' ? 'selected' : '');
	my $selIDsakhalin	= ($setIDHost eq 'sakhalin' ? 'selected' : '');
	my $selIDsiberia	= ($setIDHost eq 'siberia' ? 'selected' : '');
	
	my $setThreadNum	= $Setting->Get('BBS_THREAD_NUMBER');
	my $setContentNum	= $Setting->Get('BBS_CONTENTS_NUMBER');
	my $setContentLine	= $Setting->Get('BBS_INDEX_LINE_NUMBER');
	my $setThreadMenu	= $Setting->Get('BBS_MAX_MENU_THREAD');
	my $setUnicode		= $Setting->Get('BBS_UNICODE');
	my $setCookie		= $Setting->Get('SUBBBS_CGI_ON');
	my $setNameCookie	= $Setting->Get('BBS_NAMECOOKIE_CHECK');
	my $setMailCookie	= $Setting->Get('BBS_MAILCOOKIE_CHECK');
	my $setNewThread	= $Setting->Get('BBS_PASSWORD_CHECK');
	my $setConfirm		= $Setting->Get('BBS_NEWSUBJECT');
	my $setWeek			= $Setting->Get('BBS_YMD_WEEKS');
	my $setTripColumn	= $Setting->Get('BBS_TRIPCOLUMN');
	
	$setUnicode			= ($setUnicode eq 'pass' ? 'checked' : '');
	$setCookie			= ($setCookie eq '1' ? 'checked' : '');
	$setConfirm			= ($setConfirm eq '1' ? 'checked' : '');
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=4>Enter each setting value then press Save.</td></tr>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">ID Display</td><td><select name=ID_DISP>");
	$Page->Print("<option value=BBS_FORCE_ID $selIDforce>Display ID (e.g. ID:kC89Lv3M)");
	$Page->Print("<option value=BBS_ID_DISP $selIDdisp>Only display ID if no e-mail is entered.");
	$Page->Print("<option value=BBS_NO_ID $selIDnone>No IDs");
	$Page->Print("<option value=BBS_DISP_IP1 $selIDhost>Show hostname (e.g. 192.168.0.1.HOSTNAME)");
	$Page->Print("<option value=BBS_DISP_IP2 $selIDsakhalin>Display bare IP addresses(sakhalin) (e.g. HOST:192.168.0.1)");
	$Page->Print("<option value=BBS_DISP_IP3 $selIDsiberia>Display bare IP addresses(siberia) (e.g. HOST:192.168.0.1)");
	$Page->Print("</select></td>");
	$Page->Print("<td class=\"DetailTitle\">機種識別子(ID末尾)</td><td>");
	$Page->Print("<input type=checkbox name=BBS_SLIP $setIPSave value=on>付加する</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">Day of the week characters</td><td>");
	$Page->Print("<input type=text size=20 name=BBS_YMD_WEEKS value=\"$setWeek\"></td>");
	$Page->Print("<td class=\"DetailTitle\"><s>文字参照</s></td><td>");
	$Page->Print("<input type=checkbox name=BBS_UNICODE $setUnicode value=on>使用可能</td>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">トリップ桁数</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_TRIPCOLUMN value=\"$setTripColumn\"></td>");
	$Page->Print("<td class=\"DetailTitle\">cookie確認</td><td>");
	$Page->Print("<input type=checkbox name=SUBBBS_CGI_ON $setCookie value=on>確認あり</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Number of threads to show on board index</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_THREAD_NUMBER value=\"$setThreadNum\"></td>");
	$Page->Print("<td class=\"DetailTitle\">　　名前cookie保存</td><td>");
	$Page->Print("<input type=checkbox name=BBS_NAMECOOKIE_CHECK $setNameCookie value=on>保存</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">Number of responses to show per thread on the board index</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_CONTENTS_NUMBER value=\"$setContentNum\"></td>");
	$Page->Print("<td class=\"DetailTitle\">　　メールcookie保存</td><td>");
	$Page->Print("<input type=checkbox name=BBS_MAILCOOKIE_CHECK $setMailCookie value=on>保存</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">indexレス内容表\示行数(注)</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_INDEX_LINE_NUMBER value=\"$setContentLine\"></td>");
	$Page->Print("<td class=\"DetailTitle\">スレッド作成画面</td><td>");
	$Page->Print("<input type=checkbox name=BBS_PASSWORD_CHECK $setNewThread value=on>別画面</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">indexメニュー数</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_MAX_MENU_THREAD value=\"$setThreadMenu\"></td>");
	$Page->Print("<td class=\"DetailTitle\">スレッド作成確認画面</td><td>");
	$Page->Print("<input type=checkbox name=BBS_NEWSUBJECT $setConfirm value=on>確認あり</td></tr>");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("<tr><td colspan=4 align=left><input type=button value=\"　設定　\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETOTHER');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	インポート画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@param	$BBS	BBS情報
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSettingImport
{
	my ($Page, $SYS, $Form, $BBS) = @_;
	my (@bbsSet, $id, $name);
	
	$SYS->Set('_TITLE', 'BBS Setting Import');
	
	# 所属BBSを取得
	$SYS->Get('ADMIN')->{'SECINFO'}->GetBelongBBSList($SYS->Get('ADMIN')->{'USER'}, $BBS, \@bbsSet);
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\"><input type=radio name=IMPORT_KIND value=FROM_BBS");
	$Page->Print(" checked>既存BBSからインポート</td>");
	$Page->Print("<td><select name=IMPORT_BBS><option value=\"\">--掲示板を選択--</option>");
	
	# 掲示板一覧の出力
	foreach $id (@bbsSet) {
		$name = $BBS->Get('NAME', $id);
		$Page->Print("<option value=$id>$name</option>\n");
	}
	
	$Page->Print("</select></td></tr>");
	$Page->Print("<tr><td valign=top class=\"DetailTitle\">");
	$Page->Print("<input type=radio name=IMPORT_KIND value=FROM_DIRECT>直接インポート</td>");
	$Page->Print("<td><textarea rows=10 cols=60 wrap=off name=IMPORT_DIRECT></textarea></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"インポート\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETIMPORT');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	基本設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBaseSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = qw(BBS_SUBTITLE BBS_NONAME_NAME BBS_DELETE_NAME BBS_COOKIEPATH);
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		foreach (@inList) {
			push @$pLog, "「$_」を「" . $Form->Get($_) . '」に設定';
		}
	}
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	$Setting->Set('BBS_SUBTITLE', $Form->Get('BBS_SUBTITLE'));
	$Setting->Set('BBS_TITLE_PICTURE', $Form->Get('BBS_TITLE_PICTURE'));
	$Setting->Set('BBS_TITLE_LINK', $Form->Get('BBS_TITLE_LINK'));
	$Setting->Set('BBS_BG_PICTURE', $Form->Get('BBS_BG_PICTURE'));
	$Setting->Set('BBS_NONAME_NAME', $Form->Get('BBS_NONAME_NAME'));
	$Setting->Set('BBS_DELETE_NAME', $Form->Get('BBS_DELETE_NAME'));
	$Setting->Set('BBS_COOKIEPATH', $Form->Get('BBS_COOKIEPATH'));
	$Setting->Set('BBS_REFERER_CUSHION', $Form->Get('BBS_REFERER_CUSHION'));
	
	$Setting->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カラー設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionColorSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting, $capColor);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = ('BBS_TITLE_COLOR', 'BBS_SUBJECT_COLOR', 'BBS_BG_COLOR', 'BBS_THREAD_COLOR',
						'BBS_MAKETHREAD_COLOR', 'BBS_MENU_COLOR', 'BBS_TEXT_COLOR', 'BBS_LINK_COLOR',
						'BBS_ALINK_COLOR', 'BBS_VLINK_COLOR', 'BBS_NAME_COLOR');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		foreach (@inList, 'BBS_CAP_COLOR') {
			push @$pLog, "「$_」を「" . $Form->Get($_) . '」に設定';
		}
	}
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	$Setting->Set('BBS_TITLE_COLOR', $Form->Get('BBS_TITLE_COLOR'));
	$Setting->Set('BBS_SUBJECT_COLOR', $Form->Get('BBS_SUBJECT_COLOR'));
	$Setting->Set('BBS_BG_COLOR', $Form->Get('BBS_BG_COLOR'));
	$Setting->Set('BBS_THREAD_COLOR', $Form->Get('BBS_THREAD_COLOR'));
	$Setting->Set('BBS_MAKETHREAD_COLOR', $Form->Get('BBS_MAKETHREAD_COLOR'));
	$Setting->Set('BBS_MENU_COLOR', $Form->Get('BBS_MENU_COLOR'));
	$Setting->Set('BBS_TEXT_COLOR', $Form->Get('BBS_TEXT_COLOR'));
	$Setting->Set('BBS_LINK_COLOR', $Form->Get('BBS_LINK_COLOR'));
	$Setting->Set('BBS_ALINK_COLOR', $Form->Get('BBS_ALINK_COLOR'));
	$Setting->Set('BBS_VLINK_COLOR', $Form->Get('BBS_VLINK_COLOR'));
	$Setting->Set('BBS_NAME_COLOR', $Form->Get('BBS_NAME_COLOR'));
	$capColor = $Form->Get('BBS_CAP_COLOR');
	$capColor =~ s/[^\w\d\#]//ig;
	$Setting->Set('BBS_CAP_COLOR', $capColor);
	
	$Setting->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	制限設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my $bbsLN;
		$bbsLN = $Form->Get('BBS_LINE_NUMBER') /2;
		$bbsLN = ( $bbsLN == int($bbsLN) ? $bbsLN : int($bbsLN+1) );
		$Form->Set( 'BBS_LINE_NUMBER', $bbsLN );

		my @inList = qw(BBS_SUBJECT_COUNT BBS_NAME_COUNT BBS_MAIL_COUNT BBS_MESSAGE_COUNT
						BBS_LINE_NUMBER BBS_COLUMN_NUMBER BBS_DATMAX
						timecount timeclose BBS_THREAD_TATESUGI BBS_TATESUGI_COUNT2
						BBS_TATESUGI_HOUR BBS_TATESUGI_COUNT);
		# 入力有無
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		# 規定外文字
		if (!$Form->IsNumber(\@inList)) {
			return 1002;
		}
		foreach (@inList) {
			push @$pLog, "「$_」を「" . $Form->Get($_) . '」に設定';
		}
	}
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	if ( $Form->Get('timeclose') eq 0 && $Form->Get('timecount') eq 0 ) {
		$Form->Set('timeclose' ,'');
		$Form->Set('timecount' ,'');
	}
	
	$Setting->Set('BBS_SUBJECT_MAX', $Form->Get('BBS_SUBJECT_MAX'));
	$Setting->Set('BBS_RES_MAX', $Form->Get('BBS_RES_MAX'));
	$Setting->Set('BBS_SUBJECT_COUNT', $Form->Get('BBS_SUBJECT_COUNT'));
	$Setting->Set('BBS_NAME_COUNT', $Form->Get('BBS_NAME_COUNT'));
	$Setting->Set('BBS_MAIL_COUNT', $Form->Get('BBS_MAIL_COUNT'));
	$Setting->Set('BBS_MESSAGE_COUNT', $Form->Get('BBS_MESSAGE_COUNT'));
	$Setting->Set('BBS_LINE_NUMBER',$Form->Get('BBS_LINE_NUMBER'));
	$Setting->Set('timecount', $Form->Get('timecount'));
	$Setting->Set('timeclose', $Form->Get('timeclose'));
	$Setting->Set('NANASHI_CHECK', ($Form->Equal('NANASHI_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_PROXY_CHECK', ($Form->Equal('BBS_PROXY_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_JP_CHECK', ($Form->Equal('BBS_JP_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_RAWIP_CHECK', ($Form->Equal('BBS_RAWIP_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_DATMAX', $Form->Get('BBS_DATMAX'));
	$Setting->Set('BBS_COLUMN_NUMBER', $Form->Get('BBS_COLUMN_NUMBER'));
	$Setting->Set('BBS_READONLY', $Form->Get('BBS_READONLY'));
	$Setting->Set('BBS_THREADCAPONLY', ($Form->Equal('BBS_THREADCAPONLY', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_THREADMOBILE', ($Form->Equal('BBS_THREADMOBILE', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_SAMBATIME', $Form->Get('BBS_SAMBATIME'));
	$Setting->Set('BBS_HOUSHITIME', $Form->Get('BBS_HOUSHITIME'));
	$Setting->Set('BBS_THREAD_TATESUGI', $Form->Get('BBS_THREAD_TATESUGI'));
	$Setting->Set('BBS_TATESUGI_HOUR', $Form->Get('BBS_TATESUGI_HOUR'));
	$Setting->Set('BBS_TATESUGI_COUNT', $Form->Get('BBS_TATESUGI_COUNT'));
	$Setting->Set('BBS_TATESUGI_COUNT2', $Form->Get('BBS_TATESUGI_COUNT2'));
	
	$Setting->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = qw(BBS_THREAD_NUMBER BBS_CONTENTS_NUMBER BBS_INDEX_LINE_NUMBER BBS_MAX_MENU_THREAD BBS_TRIPCOLUMN);
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		foreach (@inList) {
			push @$pLog, "「$_」を「" . $Form->Get($_) . '」に設定';
		}
	}
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	$Setting->Set('BBS_THREAD_NUMBER', $Form->Get('BBS_THREAD_NUMBER'));
	$Setting->Set('BBS_CONTENTS_NUMBER', $Form->Get('BBS_CONTENTS_NUMBER'));
	$Setting->Set('BBS_INDEX_LINE_NUMBER', $Form->Get('BBS_INDEX_LINE_NUMBER'));
	$Setting->Set('BBS_MAX_MENU_THREAD', $Form->Get('BBS_MAX_MENU_THREAD'));
	$Setting->Set('BBS_UNICODE', ($Form->Equal('BBS_UNICODE', 'on') ? 'pass' : 'change'));
	$Setting->Set('SUBBBS_CGI_ON', ($Form->Equal('SUBBBS_CGI_ON', 'on') ? '1' : ''));
	$Setting->Set('BBS_NAMECOOKIE_CHECK', ($Form->Equal('BBS_NAMECOOKIE_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_MAILCOOKIE_CHECK', ($Form->Equal('BBS_MAILCOOKIE_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_PASSWORD_CHECK', ($Form->Equal('BBS_PASSWORD_CHECK', 'on') ? 'checked' : ''));
	$Setting->Set('BBS_NEWSUBJECT', ($Form->Equal('BBS_NEWSUBJECT', 'on') ? '1' : ''));
	$Setting->Set('BBS_YMD_WEEKS', $Form->Get('BBS_YMD_WEEKS'));
	$Setting->Set('BBS_TRIPCOLUMN', $Form->Get('BBS_TRIPCOLUMN'));
	$Setting->Set('BBS_SLIP', ($Form->Equal('BBS_SLIP', 'on') ? 'checked' : ''));
	
	# ID表示設定
	# 酷いけど仕方ないね…
	# HOST表示
	if ( $Form->Equal('ID_DISP', 'BBS_DISP_IP1') ) {
		$Setting->Set('BBS_DISP_IP', 'checked');
		$Setting->Set('BBS_FORCE_ID', '');
		$Setting->Set('BBS_NO_ID', '');
	}
	# sakhalin
	elsif ( $Form->Equal('ID_DISP', 'BBS_DISP_IP2') ) {
		$Setting->Set('BBS_DISP_IP', 'sakhalin');
		$Setting->Set('BBS_FORCE_ID', '');
		$Setting->Set('BBS_NO_ID', '');
	}
	# siberia
	elsif ( $Form->Equal('ID_DISP', 'BBS_DISP_IP3') ) {
		$Setting->Set('BBS_DISP_IP', 'siberia');
		$Setting->Set('BBS_FORCE_ID', '');
		$Setting->Set('BBS_NO_ID', '');
	}
	elsif ( $Form->Equal('ID_DISP', 'BBS_FORCE_ID') ) {
		$Setting->Set('BBS_DISP_IP', '');
		$Setting->Set('BBS_FORCE_ID', 'checked');
		$Setting->Set('BBS_NO_ID', '');
	}
	elsif ( $Form->Equal('ID_DISP', 'BBS_NO_ID') ) {
		$Setting->Set('BBS_DISP_IP', '');
		$Setting->Set('BBS_FORCE_ID', '');
		$Setting->Set('BBS_NO_ID', 'checked');
	}
	else {
		$Setting->Set('BBS_DISP_IP', '');
		$Setting->Set('BBS_FORCE_ID', '');
		$Setting->Set('BBS_NO_ID', '');
	}
	
	$Setting->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	設定インポート
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionSettingImport
{
	my ($Sys, $Form, $pLog, $BBS) = @_;
	my ($Setting, @setKeys, @importKeys, $key);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = ('IMPORT_BBS');
		
		# 既存掲示板からのインポート時のみ
		if ($Form->Equal('IMPORT_KIND', 'FROM_BBS')) {
			# 入力有無
			if (! $Form->IsInput(\@inList)) {
				return 1001;
			}
		}
	}
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	# importするキーを設定する
	$Setting->GetKeySet(\@setKeys);
	foreach (@setKeys) {
		if ($_ ne 'BBS_TITLE' && $_ ne 'BBS_SUBTITLE') {
			push @importKeys, $_;
		}
	}
	
	# 既存BBSからインポート
	if ($Form->Equal('IMPORT_KIND', 'FROM_BBS')) {
		my $bbs = $BBS->Get('DIR', $Form->Get('IMPORT_BBS'));
		my $baseSetting = ISILDUR->new;
		my $path = $Sys->Get('BBSPATH') . "/$bbs/SETTING.TXT";
		
		push @$pLog, "■掲示板「$path」から設定情報をインポートします。";
		
		# 既存BBSのSETTING.TXTを読み込む
		if ($baseSetting->LoadFrom($path)) {
			# 設定情報を設定する
			foreach $key (@importKeys) {
				$Setting->Set($key, $baseSetting->Get($key));
				push @$pLog, "　　「$key」をインポートしました。";
			}
		}
	}
	# 直接インポート
	else {
		my $data = $Form->Get('IMPORT_DIRECT');
		my @datas = split(/\r\n|\r|\n/, $data);
		my (%setTemp, $line, $inKey);
		
		push @$pLog, '■入力内容をインポートします。';
		
		# フォーム情報から設定情報ハッシュを作成する
		foreach $line (@datas){
			($key, $data) = split(/=/, $line);
			$setTemp{$key} = $data;
		}
		# 設定情報を設定する
		foreach $key (keys %setTemp) {
			foreach $inKey (@importKeys) {
				if ($key eq $inKey) {
					$Setting->Set($key, $setTemp{$key});
					push @$pLog, "　　「$key」をインポートしました。";
				}
			}
		}
	}
	# 更新後保存
	$Setting->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
