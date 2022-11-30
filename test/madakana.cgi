#!/usr/bin/perl
#============================================================================================================
#
#	規制一覧表示用CGI
#	madakana.cgi
#	---------------------------------------------------------------------------
#	2011.03.18 start
#	2011.03.31 remake
#
#============================================================================================================

use strict;
#use warnings;
##use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
no warnings 'once';

BEGIN { use lib './perllib'; }

# CGIの実行結果を終了コードとする
exit(MADAKANA());

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi main
#	-------------------------------------------------------------------------------------
#	@param	none
#	@return	none
#
#------------------------------------------------------------------------------------------------------------
sub MADAKANA
{
	
	my ( %SYS, $Page, $err );
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# 初期化に成功したら内容を表示
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		
		# ヘッダ表示
		PrintMadaHead(\%SYS, $Page);
		
		# 内容表示
		PrintMadaCont(\%SYS, $Page);
		
		# フッタ表示
		PrintMadaFoot(\%SYS, $Page);
		
	}
	else {
		PrintMadaError(\%SYS, $Page, $err);
	}
	
	$Page->Flush(0, 0, '');
	
	return $err;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi初期化・前準備
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($pSYS, $Page) = @_;
	my (@elem, @regs, $path);
	my ($oSYS, $oCONV);
	
	require './module/melkor.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	
	$oSYS	= new MELKOR;
	$oCONV	= new GALADRIEL;
	
	%$pSYS = (
		'SYS'	=> $oSYS,
		'CONV'	=> $oCONV,
		'PAGE'	=> $Page,
		'CODE'	=> 'UTF-8',
	);
	
	$pSYS->{'FORM'} = SAMWISE->new($oSYS->Get('BBSGET')),
	
	# システム初期化
	$oSYS->Init();
	
	
	# 夢が広がりんぐ
	$oSYS->{'MainCGI'} = $pSYS;
	
	# ホスト情報設定(DNS逆引き)
	$ENV{'REMOTE_HOST'} = $oCONV->GetRemoteHost() unless ($ENV{'REMOTE_HOST'});
	$pSYS->{'FORM'}->Set('HOST', $ENV{'REMOTE_HOST'});
	
	return 0;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi header output
#	-------------------------------------------------------------------------------------
#	@param	none
#	@return	none
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaHead
{
	my ($Sys, $Page) = @_;
	my ($Caption, $Banner, $code, $HOST, $ADDR);
	
	require './module/legolas.pl';
	require './module/denethor.pl';
	$Caption = new LEGOLAS;
	$Banner = new DENETHOR;
	
	$Caption->Load($Sys->{'SYS'}, 'META');
	$Banner->Load($Sys->{'SYS'});
	
	$code	= $Sys->{'CODE'};
	$HOST	= $Sys->{'FORM'}->Get('HOST');
	$ADDR	= $ENV{'REMOTE_ADDR'};
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=$code">
 <meta http-equiv="Content-Style-Type" content="text/css">
 <meta http-equiv="imagetoolbar" content="no">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>Not yet, not yet...</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n<body>\n");
	
	# Banner output
	$Banner->Print($Page, 100, 2, 0) if ($Sys->{'SYS'}->Get('BANNER'));
	
	$Page->Print(<<HTML);
<div style="color:navy;">
<h1 style="font-size:1em;font-weight:normal;margin:0;">Not yet, not yet, not yet (regulation list\)</h1>
<p style="margin:0;">
Your host [<span style="color:red;font-weight:bold;">$HOST</span>]
</p>
<p>
by <font color="green">ZeroChEN ★</font>
</p>
<p>
##############################################################################<br>
# ここから<br>
</p>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi内容出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaCont
{
	my ($Sys, $Page) = @_;
	my ($BBS, $vUser, $HOST, $ADDR, $BBSpath, @BBSkey, %BBSs, $path, $check, $line, $color );
	
	require './module/nazguls.pl';
	$BBS	= new NAZGUL;
	$BBS->Load($Sys->{'SYS'});
	
	require './module/faramir.pl';
	$vUser = FARAMIR->new;
	
	$HOST	= $Sys->{'FORM'}->Get('HOST');
	$ADDR	= $ENV{'REMOTE_ADDR'};
	$BBSpath	= $Sys->{'SYS'}->Get('BBSPATH');
	
	#$sys->Set('HITS', $line);
	# BBSセットの取得
	$BBS->GetKeySet('ALL', '', \@BBSkey);
	
	# ハッシュに詰め込む
	foreach my $id (@BBSkey) {
		$BBSs{$BBS->Get('DIR', $id)} = $BBS->Get('NAME', $id);
	}
	
	foreach my $dir ( keys %BBSs ) {
		
		# 板ディレクトリに.0ch_hiddenというファイルがあれば読み飛ばす
		next if ( -e "$BBSpath/$dir/.0ch_hidden" );
		
		$Sys->{'SYS'}->Set('BBS', $dir);
		$vUser->Load($Sys->{'SYS'});
		$check = $vUser->Check($HOST, $ADDR);
		
		$color = "red";
		
		$Page->Print('<p>'."\n");
		$Page->Print('#-----------------------------------------------------------------------------<br>'."\n");
		$Page->Print("# <a href=\"$BBSpath/$dir/\">$BBSs{$dir}</a> [ $dir ]<br>\n");
		$Page->Print('#-----------------------------------------------------------------------------<br>'."\n");
		
		$path = "$BBSpath/$dir/info/access.cgi";
		
		if ( -e $path && open(SEC, '<', $path) ) {
			flock(FILE, 1);
			
			$line = <SEC>;
			chomp $line;
			my ( $type, $method ) = split(/<>/, $line, 2);
			
			if ( $type eq 'enable' ) {
				$Page->Print('<font color="red">※Only the following users are allowed to write on this board:</font><br>'."\n");
				$color = "blue";
			}
			
			while ( <SEC> ) {
				next if( $_ =~ /(?:disable|enable)<>(?:disable|host)\n/ );
				chomp;
				if ( $Sys->{'SYS'}->Get('HITS') eq $_ ) {
					$_ = '<font color="'.$color.'"><b>'.$_.'</b></font>';
				}
				$_ .= "\n";
				s/\n/<br>/g;
				s/(http:\/\/.*)<br>/<a href="$1" target="_blank">$1<\/a><br>/g;
				$Page->Print($_."\n");
			}
			close(SEC);
		}
		else {
			$Page->Print('<span style="color:#AAA">Cannot open access.cgi.</span><br>'."\n");
		}
		
		$Page->Print('</p>'."\n");
		
	}
	

	
}

sub PrintMadaFoot
{
	my ($Sys, $Page) = @_;
	my ($ver, $cgipath);
	
	$ver		= $Sys->{'SYS'}->Get('VERSION');
	$cgipath	= $Sys->{'SYS'}->Get('CGIPATH');
	
	$Page->Print(<<HTML);
<p>
# so far<br>
##############################################################################<br>
</p>
</div>

<hr>

<div>
<a href="https://github.com/RealAngeleno/ZeroChEN/">ZeroChEN</a>
MADAKANA.CGI - $ver
</div>

</body>
</html>
HTML

}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgiエラー表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaError
{
	my ($Sys, $Page, $err) = @_;
	my ($code);
	
	$code = 'UTF-8';
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><head><title>ERROR!! </title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head><!--nobanner-->');
	$Page->Print('<html><body>');
	$Page->Print("<b>$err</b>");
	$Page->Print('</body></html>');
}


