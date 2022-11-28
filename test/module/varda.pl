#============================================================================================================
#
#	bbs.cgi支援モジュール
#
#============================================================================================================
package	VARDA;

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
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'BANNER'	=> undef,
		'CODE'		=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化
#	-------------------------------------------------------------------------------------
#	@param	$Sys		MELKOR
#	@param	$Setting	ISILDUR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys, $Setting) = @_;
	
	require './module/baggins.pl';
	require './module/galadriel.pl';
	require './module/denethor.pl';
	
	# 使用モジュールを設定
	$this->{'SYS'} = $Sys;
	$this->{'THREADS'} = BILBO->new;
	$this->{'CONV'} = GALADRIEL->new;
	$this->{'BANNER'} = DENETHOR->new;
	$this->{'CODE'} = 'sjis';
	
	if (!defined $Setting) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	else {
		$this->{'SET'} = $Setting;
	}
	
	# 情報の読み込み
	$this->{'THREADS'}->Load($Sys);
	$this->{'BANNER'}->Load($Sys);
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	生成されたら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub CreateIndex
{
	my $this = shift;
	
	my $Sys = $this->{'SYS'};
	my $Threads = $this->{'THREADS'};
	my $bbsSetting = $this->{'SET'};
	
	# CREATEモード、またはスレッドがindex表示範囲内の場合のみindexを更新する
	if ($Sys->Equal('MODE', 'CREATE')
		|| ($Threads->GetPosition($Sys->Get('KEY')) < $bbsSetting->Get('BBS_MAX_MENU_THREAD'))) {
		
		require './module/thorin.pl';
		require './module/legolas.pl';
		my $Index = THORIN->new;
		my $Caption = LEGOLAS->new;
		
		PrintIndexHead($this, $Index, $Caption);
		PrintIndexMenu($this, $Index);
		PrintIndexPreview($this, $Index);
		PrintIndexFoot($this, $Index, $Caption);
		
		my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/index.html';
		$Index->Flush(1, $Sys->Get('PM-TXT'), $path);
		
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	i/index.html生成
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub CreateIIndex
{
	my $this = shift;
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	# 前準備
	my $Sys = $this->{'SYS'};
	my $Threads = $this->{'THREADS'};
	my $Set = $this->{'SET'};
	my $Conv = $this->{'CONV'};
	my $bbs = $Sys->Get('BBS');
	
	# HTMLヘッダの出力
	my $title = $Set->Get('BBS_TITLE');
	my $code = $this->{'CODE'};
	$Page->Print("<html><!--nobanner--><head><title>$title</title>");
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print("</head><body><center>$title</center>");
	
	# バナー表示
	$this->{'BANNER'}->Print($Page, 100, 3, 1)  if ($Sys->Get('BANNER') & 3);
	
	# 全スレッドを取得
	my @threadSet = ();
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	# スレッド分だけループをまわす
	my $menuNum = $Set->Get('BBS_MAX_MENU_THREAD');
	my $i = 0;
	foreach my $key (@threadSet) {
		last if (++$i > $menuNum);
		
		my $name = $Threads->Get('SUBJECT', $key);
		my $res = $Threads->Get('RES', $key);
		my $path = $Conv->CreatePath($Sys, 'O', $bbs, $key, 'l10');
		
		$Page->Print("<a href=\"$path\">$i: $name($res)</a><br> \n");
	}
	
	# フッタ部分の出力
	my $cgiPath = $Sys->Get('CGIPATH');
	my $pathf = "$cgiPath/p.cgi" . ($Sys->Get('PATHKIND') ? "?bbs=$bbs&st=$i" : "/$bbs/$i");
	$Page->Print("<hr>");
	$Page->Print("<a href=\"$pathf\">続き</a>\n");
	$Page->Print("<form action=\"$cgiPath/bbs.cgi?guid=ON\" method=\"POST\">");
	$Page->Print("<input type=hidden name=bbs value=$bbs>");
	$Page->Print("<input type=hidden name=mb value=on>");
	$Page->Print("<input type=hidden name=thread value=on>");
	$Page->Print("<input type=submit value=\"スレッド作成\">");
	$Page->Print("</form><hr></body></html>\n");
	
	# i/index.htmlに書き込み
	my $pathi = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$pathi/i/index.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	subback.html生成
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub CreateSubback
{
	my $this = shift;
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	my $Sys = $this->{'SYS'};
	my $Threads = $this->{'THREADS'};
	my $Set = $this->{'SET'};
	my $Conv = $this->{'CONV'};
	
	require './module/legolas.pl';
	my $Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	# HTMLヘッダの出力
	my $title = $Set->Get('BBS_TITLE');
	my $code = $this->{'CODE'};
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title - Thread List</title>\n\n");
	$Page->Print("</head>\n<body>\n\n");
	
	# バナー表示
	if ($Sys->Get('BANNER') & 5) {
		$this->{'BANNER'}->Print($Page, 100, 2, 0);
	}
	
	$Page->Print("<div class=\"threads\">");
	$Page->Print("<small>\n");
	
	# 全スレッドを取得
	my @threadSet = ();
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	# スレッド分だけループをまわす
	my $bbs = $Sys->Get('BBS');
	my $max = $Sys->Get('SUBMAX');
	my $i = 0;
	foreach my $key (@threadSet) {
		last if (++$i > $max);
		
		my $name = $Threads->Get('SUBJECT', $key);
		my $res = $Threads->Get('RES', $key);
		my $path = $Conv->CreatePath($Sys, 0, $bbs, $key, 'l50');
		
		$Page->Print("<a href=\"$path\" target=\"_blank\">$i: $name($res)</a>&nbsp;&nbsp;\n");
	}
	
	# フッタ部分の出力
	my $cgipath = $Sys->Get('CGIPATH');
	my $version = $Sys->Get('VERSION');
	$Page->Print(<<HTML);
</small>
</div>

<div align="right" style="margin-top:1em;">
<small><a href="./kako/" target="_blank"><b>Click here to enter the log warehouse.</b></a></small>
</div>

<hr>

<div align="right">
$version
</div>

</body>
</html>
HTML
	
	# subback.htmlに書き込み
	my $paths = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$paths/subback.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(ヘッダ部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Caption	
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexHead
{
	my $this = shift;
	my ($Page, $Caption) = @_;
	
	$Caption->Load($this->{'SYS'}, 'META');
	my $title = $this->{'SET'}->Get('BBS_TITLE');
	my $link = $this->{'SET'}->Get('BBS_TITLE_LINK');
	my $image = $this->{'SET'}->Get('BBS_TITLE_PICTURE');
#	my $code = $this->{'CODE'};
	
	# HTMLヘッダの出力
	$Page->Print(<<HEAD);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
 
 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">
 <meta http-equiv="Content-Script-Type" content="text/javascript">
 
HEAD
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title</title>\n\n");
	
	# cookie用scriptの出力
	if ($this->{'SET'}->Equal('SUBBBS_CGI_ON', 1)) {
		require './module/radagast.pl';
		RADAGAST::Print(undef, $Page);
	}
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>タグ出力
	{
		my @work = ();
		$work[0] = $this->{'SET'}->Get('BBS_BG_COLOR');
		$work[1] = $this->{'SET'}->Get('BBS_TEXT_COLOR');
		$work[2] = $this->{'SET'}->Get('BBS_LINK_COLOR');
		$work[3] = $this->{'SET'}->Get('BBS_ALINK_COLOR');
		$work[4] = $this->{'SET'}->Get('BBS_VLINK_COLOR');
		$work[5] = $this->{'SET'}->Get('BBS_BG_PICTURE');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\" background=\"$work[5]\">\n");

	}
	$Page->Print("<a name=\"top\"></a>\n");
	
	# 看板画像表示あり
	if ($image ne '') {
		$Page->Print("<div align=\"center\">");
		# 看板画像からのリンクあり
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$link\"></a>");
		}
		# 看板画像にリンクはなし
		else {
			$Page->Print("<img src=\"$image\" border=\"0\" alt=\"$link\">");
		}
		$Page->Print("</div>\n");
	}
	
	# ヘッダテーブルの表示
	$Caption->Load($this->{'SYS'}, 'HEAD');
	$Caption->Print($Page, $this->{'SET'});
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(スレッドメニュー部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexMenu
{
	my $this = shift;
	my ($Page) = @_;
	
	my $Conv = $this->{'CONV'};
	my $menuCol = $this->{'SET'}->Get('BBS_MENU_COLOR');
	
	# バナーの表示
	$this->{'BANNER'}->Print($Page, 95, 0, 0) if ($this->{'SYS'}->Get('BANNER') & 3);
	
	$Page->Print(<<MENU);

<a name="menu"></a>
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$menuCol" style="margin:1.2em auto;" align="center">
 <tr>
  <td>
  <small>
MENU
	
	my @threadSet = ();
	$this->{'THREADS'}->GetKeySet('ALL', '', \@threadSet);
	
	# スレッド分だけループをまわす
	my $prevNum = $this->{'SET'}->Get('BBS_THREAD_NUMBER');
	my $menuNum = $this->{'SET'}->Get('BBS_MAX_MENU_THREAD');
	my $max = $this->{'SYS'}->Get('SUBMAX');
	my $i = 0;
	foreach my $key (@threadSet) {
		last if ((++$i > $menuNum) || ($i > $max));
		
		my $name = $this->{'THREADS'}->Get('SUBJECT', $key);
		my $res = $this->{'THREADS'}->Get('RES', $key);
		my $path = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
		
		# プレビュースレッドの場合はプレビューへのリンクを貼る
		if ($i <= $prevNum) {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i:</a> ");
			$Page->Print("<a href=\"#$i\">$name($res)</a>　\n");
		}
		else {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i: $name($res)</a>　\n");
		}
	}
	$Page->Print(<<MENU);
  </small>
  <div align="right"><small><b><a href="./subback.html">Thread List</a></b></small></div>
  </td>
 </tr>
</table>

MENU
	
	# サブバナーの表示(表示したら空行をひとつ挿入)
	if ($this->{'BANNER'}->PrintSub($Page)) {
		$Page->Print("\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(スレッドプレビュー部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexPreview
{
	my $this = shift;
	my ($Page) = @_;
	
	# 拡張機能ロード
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($this->{'SYS'});
	
	# 有効な拡張機能一覧を取得
	my @commands = ();
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	my $count = 0;
	foreach my $id (@pluginSet) {
		# タイプがread.cgiの場合はロードして実行
		if ($Plugin->Get('TYPE', $id) & 8) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			if (-e "./plugin/$file") {
				require "./plugin/$file";
				my $Config = PLUGINCONF->new($Plugin, $id);
				$commands[$count++] = $className->new($Config);
			}
		}
	}
	
	require './module/gondor.pl';
	my $Dat = ARAGORN->new;
	
	my @threadSet = ();
	$this->{'THREADS'}->GetKeySet('ALL', '', \@threadSet);
	
	# 前準備
	my $prevNum = $this->{'SET'}->Get('BBS_THREAD_NUMBER');
	my $threadNum = (scalar(@threadSet) > $prevNum ? $prevNum : scalar(@threadSet));
	my $tblCol = $this->{'SET'}->Get('BBS_THREAD_COLOR');
	my $ttlCol = $this->{'SET'}->Get('BBS_SUBJECT_COLOR');
	my $prevT = $threadNum;
	my $nextT = ($threadNum > 1 ? 2 : 1);
	my $Conv = $this->{'CONV'};
	my $basePath = $this->{'SYS'}->Get('BBSPATH') . '/' . $this->{'SYS'}->Get('BBS');
	my $max = $this->{'SYS'}->Get('SUBMAX');
	
	my $cnt = 0;
	foreach my $key (@threadSet) {
		last if (++$cnt > $prevNum || $cnt > $max);
		
		my $subject = $this->{'THREADS'}->Get('SUBJECT', $key);
		my $res = $this->{'THREADS'}->Get('RES', $key);
		$nextT = 1 if ($cnt == $threadNum);
		
		# ヘッダ部分の表示
		$Page->Print(<<THREAD);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>
  <a name="$cnt"></a>
  <div align="right"><a href="#menu">■</a><a href="#$prevT">▲</a><a href="#$nextT">▼</a></div>
  <div style="font-weight:bold;margin-bottom:0.2em;">【$cnt:$res】<font size="+2" color="$ttlCol">$subject</font></div>
  <dl style="margin-top:0px;">
THREAD
		
		# プレビューの表示
		my $datPath = "$basePath/dat/$key.dat";
		$Dat->Load($this->{'SYS'}, $datPath, 1);
		$this->{'SYS'}->Set('KEY', $key);
		PrintThreadPreviewOne($this, $Page, $Dat, \@commands);
		$Dat->Close();
		
		# フッタ部分の表示
		my $allPath = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '');
		my $lastPath = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
		my $numPath = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '1-100');
		$Page->Print(<<KAKIKO);
    <div style="font-weight:bold;">
     <a href="$allPath">Read all</a>
     <a href="$lastPath">Last 50 Posts</a>
     <a href="$numPath">1-100</a>
     <a href="#top">board top</a>
     <a href="./">refresh</a>
    </div>
    </blockquote>
   </blockquote>
  </form>
  </td>
 </tr>
</table>

KAKIKO
		
		# カウンタの更新
		$nextT++;
		$prevT++;
		$prevT = 1 if ($cnt == 1);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(フッタ部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Caption	
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexFoot
{
	my $this = shift;
	my ($Page, $Caption) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Set = $this->{'SET'};
	my $tblCol = $Set->Get('BBS_MAKETHREAD_COLOR');
	my $cgipath = $Sys->Get('CGIPATH');
	my $bbs = $Sys->Get('BBS');
	my $ver = $Sys->Get('VERSION');
	my $samba = int ($Set->Get('BBS_SAMBATIME', '') eq ''
					? $Sys->Get('DEFSAMBA') : $Set->Get('BBS_SAMBATIME'));
	my $tm = time;
	
	# スレッド作成画面を別画面で表示
	if ($Set->Equal('BBS_PASSWORD_CHECK', 'checked')) {
		$Page->Print(<<FORM);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" align="center">
 <tr>
  <td>
  <form method="POST" action="$cgipath/bbs.cgi?guid=ON" style="margin:1.2em 0;">
  <input type="submit" value="Create New Thread"><br>
  <input type="hidden" name="bbs" value="$bbs">
  <input type="hidden" name="time" value="$tm">
  </form>
  </td>
 </tr>
</table>
FORM
	}
	# スレッド作成フォームはindexと同じ画面に表示
	else {
		$Page->Print(<<FORM);
<form method="POST" action="$cgipath/bbs.cgi?guid=ON">
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#CCFFCC" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>&lrm;</td>
  <td nowrap>
  Title: <input type="text" name="subject" size="40"><input type="submit" value="Post"><br>
  Name: <input type="text" name="FROM" size="19"> E-mail：<input type="text" name="mail" size="19"><br>
  Message: <textarea rows="5" cols="60" name="MESSAGE"></textarea>
  <input type="hidden" name="bbs" value="$bbs">
  <input type="hidden" name="time" value="$tm">
  </td>
 </tr>
</table>
</form>
FORM
	}
	
	# footの表示
	$Caption->Load($Sys, 'FOOT');
	$Caption->Print($Page, $Set);
	
	$Page->Print(<<FOOT);
<div style="margin-top:1.2em;">
<a href="http://zerochplus.sourceforge.jp/">0chPlus</a>
BBS.CGI - $ver (Perl)
@{[ $Sys->Get('BBQ') ? '+<a href="http://bbq.uso800.net/" target="_blank">BBQ</a>' : '' ]}
@{[ $Sys->Get('BBX') ? '+BBX' : '' ]}
+Samba24=$samba<br>
You've reached the end...</div>

FOOT
	
	$Page->Print("</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(スレッドプレビュー部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Dat		
#	@param	$commands	
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadPreviewOne
{
	my $this = shift;
	my ($Page, $Dat, $commands) = @_;
	
	my $Sys = $this->{'SYS'};
	
	# 前準備
	my $contNum = $this->{'SET'}->Get('BBS_CONTENTS_NUMBER');
	my $cgiPath = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	my $bbs = $Sys->Get('BBS');
	my $key = $Sys->Get('KEY');
	my $tm = time;
	
	# 表示数の正規化
	my ($start, $end) = $this->{'CONV'}->RegularDispNum($Sys, $Dat, 1, $contNum, $contNum);
	$start++ if ($start == 1);
	
	# 1の表示
	PrintResponse($this, $Page, $Dat, $commands, 1);
	# 残りの表示
	for (my $i = $start; $i <= $end; $i++) {
		PrintResponse($this, $Page, $Dat, $commands, $i);
	}
	
	# 書き込みフォームの表示
	$Page->Print(<<KAKIKO);
  </dl>
  <form method="POST" action="$cgiPath/bbs.cgi?guid=ON">
   <blockquote>
   <input type="hidden" name="bbs" value="$bbs">
   <input type="hidden" name="key" value="$key">
   <input type="hidden" name="time" value="$tm">
   <input type="submit" value="Post" name="submit"> 
   Name: <input type="text" name="FROM" size="19">
   E-mail: <input type="text" name="mail" size="19"><br>
   <blockquote style="margin-top:0px;">
    <textarea rows="5" cols="64" name="MESSAGE"></textarea>
KAKIKO
	
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(レス表示部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Dat		
#	@param	$commands	
#	@param	$n			
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my $this = shift;
	my ($Page, $Dat, $commands, $n) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Conv = $this->{'CONV'};
	
	my $pdat = $Dat->Get($n - 1);
	return if (!defined $pdat);
	
	my @elem = split(/<>/, $$pdat, -1);
	my $contLen = length $elem[3];
	my $contLine = $Conv->GetTextLine(\$elem[3]);
	my $nameCol = $this->{'SET'}->Get('BBS_NAME_COLOR');
	my $dispLine = $this->{'SET'}->Get('BBS_INDEX_LINE_NUMBER');
	
	# URLと引用個所の適応
	$Conv->ConvertURL($Sys, $this->{'SET'}, 0, \$elem[3]);
	$Conv->ConvertQuotation($Sys, \$elem[3], 0);
	
	# 拡張機能を実行
	$Sys->Set('_DAT_', \@elem);
	$Sys->Set('_NUM_', $n);
	foreach my $command (@$commands) {
		$command->execute($this->{'SYS'}, undef, 8);
	}
	
	$Page->Print("   <dt>$n Name: ");
	
	# メール欄有り
	if ($elem[1] eq '') {
		$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
	}
	# メール欄無し
	else {
		$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
	}
	
	# 表示行数内ならすべて表示する
	if ($contLine <= $dispLine || $n == 1) {
		$Page->Print("：$elem[2]</dt>\n    <dd>$elem[3]<br><br></dd>\n");
	}
	# 表示行数を超えたら省略表示を付加する
	else {
		my @dispBuff = split(/<br>/i, $elem[3]);
		my $path = $Conv->CreatePath($Sys, 0, $Sys->Get('BBS'), $Sys->Get('KEY'), "${n}n");
		
		$Page->Print("：$elem[2]</dt>\n    <dd>");
		for (my $k = 0; $k < $dispLine; $k++) {
			$Page->Print("$dispBuff[$k]<br>");
		}
		$Page->Print("<font color=\"green\">Comment too long... to read the whole thing, click ");
		$Page->Print("<a href=\"$path\" target=\"_blank\">here</a>");
		$Page->Print(".</font><br><br></dd>\n");
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
