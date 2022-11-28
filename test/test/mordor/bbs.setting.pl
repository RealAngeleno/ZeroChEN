#============================================================================================================
#
#	�f���Ǘ� - �f���ݒ� ���W���[��
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
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���W���[���I�u�W�F�N�g
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
#	�\�����\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
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
	
	# �f�����̓ǂݍ��݂ƃO���[�v�ݒ�
	if (! defined $BBS) {
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	}
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE, $pSys, $Sys->Get('BBS'));
	
	if ($subMode eq 'SETINFO') {													# �ݒ�����
		PrintSettingInfo($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETBASE') {													# ��{�ݒ���
		PrintBaseSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETCOLOR') {												# �J���[�ݒ���
		PrintColorSetting($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'SETCOLORC') {												# �J���[�ݒ�m�F���
		PrintColorSetting($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'SETLIMIT') {												# �����ݒ���
		PrintLimitSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETOTHER') {												# ���̑��ݒ���
		PrintOtherSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SETIMPORT') {												# �C���|�[�g���
		PrintSettingImport($Page, $Sys, $Form, $BBS);
	}
	elsif ($subMode eq 'COMPLETE') {												# �ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�f���ݒ菈��', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �ݒ莸�s���
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	# �f������ݒ�
	$Page->HTMLInput('hidden', 'TARGET_BBS', $Form->Get('TARGET_BBS'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME', $Form->Get('TARGET_BBS')), 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $err, $BBS);
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	# �Ǘ�����o�^
	$BBS->Load($Sys);
	$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	$Sys->Set('ADMIN', $pSys);
	$pSys->{'SECINFO'}->SetGroupInfo($Sys->Get('BBS'));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 9999;
	
	if ($subMode eq 'SETBASE') {													# ��{�ݒ�
		$err = FunctionBaseSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETCOLOR') {												# �J���[�ݒ�
		$err = FunctionColorSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETLIMIT') {												# �����ݒ�
		$err = FunctionLimitSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETOTHER') {												# ���̑��ݒ�
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETORIGIN') {												# �I���W�i���ݒ�
		$err = FunctionOriginalSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SETIMPORT') {												# �C���|�[�g
		$err = FunctionSettingImport($Sys, $Form, $this->{'LOG'}, $BBS);
	}
	
	# �������ʕ\��
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
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys, $bbs) = @_;
	
	$Base->SetMenu('�ݒ���', "'bbs.setting','DISP','SETINFO'");
	
	# �Ǘ��O���[�v�ݒ茠���̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, $ZP::AUTH_BBSSETTING, $bbs)){
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('��{�ݒ�', "'bbs.setting','DISP','SETBASE'");
		$Base->SetMenu('�J���[�ݒ�', "'bbs.setting','DISP','SETCOLOR'");
		$Base->SetMenu('�����E�K���ݒ�', "'bbs.setting','DISP','SETLIMIT'");
		$Base->SetMenu('���̑��ݒ�', "'bbs.setting','DISP','SETOTHER'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('�ݒ�C���|�[�g', "'bbs.setting','DISP','SETIMPORT'");
	}
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('�V�X�e���Ǘ��֖߂�', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	�ݒ����ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
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
#	��{�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
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
	$Page->Print("<tr><td colspan=2>�e�ݒ�l����͂���[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�T�u�^�C�g��</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_SUBTITLE value=\"$setSubTitle\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index�Ŕ摜</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_TITLE_PICTURE value=\"$setKanban\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index�Ŕ����N</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_TITLE_LINK value=\"$setKnabanLink\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index�w�i�摜</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_BG_PICTURE value=\"$setBackPict\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">����������</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_NONAME_NAME value=\"$setNoName\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�폜����</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_DELETE_NAME value=\"$setAbone\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">cookie�ۑ��p�X</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_COOKIEPATH value=\"$setCookiePath\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���t�@���N�b�V����</td><td>");
	$Page->Print("<input type=text size=80 name=BBS_REFERER_CUSHION value=\"$setRefCushion\"></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"�@�ݒ�@\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETBASE');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�J���[�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$flg	���[�h(0:�\�� 1:�m�F)
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintColorSetting
{
	my ($Page, $SYS, $Form, $flg) = @_;
	my ($Setting);
	my ($setIndexTitle, $setThreadTitle, $setIndexBG, $setThreadBG, $setCreateBG);
	my ($setMenuBG, $setText, $setLink, $setLinkA, $setLinkV, $setName, $setCap);
	
	$SYS->Set('_TITLE', 'BBS Color Setting');
	
	# SETTING.TXT����l���擾
	if ($flg == 0) {
		require './module/isildur.pl';
		$Setting = ISILDUR->new;
		$Setting->Load($SYS);
	}
	# �t�H�[����񂩂�l���擾
	else {
		$Setting = $Form;
	}
	
	# �ݒ�l���擾
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
	$Page->Print("<tr><td colspan=6>�e�ݒ�F����͂���[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=6><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index�w�i�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_BG_COLOR value=\"$setIndexBG\">");
	$Page->Print("</td><td bgcolor=$setIndexBG></td>");
	$Page->Print("<td class=\"DetailTitle\">�e�L�X�g�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_TEXT_COLOR value=\"$setText\">");
	$Page->Print("</td><td><font color=$setText>�e�L�X�g</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">index���j���[�w�i�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MENU_COLOR value=\"$setMenuBG\">");
	$Page->Print("</td><td bgcolor=$setMenuBG></td>");
	$Page->Print("<td class=\"DetailTitle\">���O�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_NAME_COLOR value=\"$setName\">");
	$Page->Print("</td><td><font color=$setName>���O</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�X���b�h�쐬�w�i�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MAKETHREAD_COLOR value=\"$setCreateBG\">");
	$Page->Print("</td><td bgcolor=$setCreateBG></td>");
	$Page->Print("<td class=\"DetailTitle\">�����N�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_LINK_COLOR value=\"$setLink\">");
	$Page->Print("</td><td><font color=$setLink>�����N</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�X���b�h�w�i�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_THREAD_COLOR value=\"$setThreadBG\">");
	$Page->Print("</td><td bgcolor=$setThreadBG></td>");
	$Page->Print("<td class=\"DetailTitle\">�����N�F(�A���J�[��)</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_ALINK_COLOR value=\"$setLinkA\">");
	$Page->Print("</td><td><font color=$setLinkA>�����N(�A���J�[)</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">index�^�C�g���F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_TITLE_COLOR value=\"$setIndexTitle\">");
	$Page->Print("</td><td><font color=$setIndexTitle>index�^�C�g��</font></td>");
	$Page->Print("<td class=\"DetailTitle\">�����N�F(�K��ς�)</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_VLINK_COLOR value=\"$setLinkV\">");
	$Page->Print("</td><td><font color=$setLinkV>�����N(�K��ς�)</font></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�X���b�h�^�C�g���F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_SUBJECT_COLOR value=\"$setThreadTitle\">");
	$Page->Print("</td><td><font color=$setThreadTitle>�X���b�h�^�C�g��</font></td>");
	$Page->Print("<td class=\"DetailTitle\">�L���b�v�F</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_CAP_COLOR value=\"$setCap\">");
	$Page->Print("</td><td><font color=$setName><font color=$setCap>���O</font></font></td></tr>\n");
	$Page->Print("<tr><td colspan=6><hr></td></tr>");
	
	# �X���b�h�v���r���[�̕\��
	if (1) {
		$Page->Print("<tr><td class=\"DetailTitle\" colspan=3>index�v���r���[</td>");
		$Page->Print("<td class=\"DetailTitle\" colspan=3>�X���b�h�v���r���[</td></tr>");
		$Page->Print("<tr><td colspan=3 bgcolor=$setIndexBG>");
		$Page->Print("<center><font color=$setIndexTitle>index�^�C�g��</font><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setMenuBG border><td>�w�b�_</td></table><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setMenuBG border><td>���j���[</td></table><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setThreadBG border><td>");
		$Page->Print("<font color=$setThreadTitle>�X���b�h�^�C�g��</font><br><br>");
		$Page->Print("<font color=$setText>�e�L�X�g</font><br></td></table><br>");
		$Page->Print("<table width=100% cellspacing=7 bgcolor=$setCreateBG border><td>�X���b�h�쐬</td>");
		$Page->Print("</table><br></center></td>");
		$Page->Print("<td colspan=3 bgcolor=$setThreadBG valign=top><font color=$setThreadTitle>");
		$Page->Print("�X���b�h�^�C�g��</font><br><br>1 <font color=$setName>���O��<font color=$setCap>�L���b�v ��</font></font><br>");
		$Page->Print("�@<font color=$setLink><u>http://---</u></font><br>");
		$Page->Print("�@<font color=$setLinkV><u>http://---</u></font><br>");
		$Page->Print("</td></tr>");
		$Page->Print("<tr><td colspan=6><hr></td></tr>");
	}
	$Page->Print("<tr><td colspan=6 align=left>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" onclick=\"DoSubmit");
	$Page->Print("('bbs.setting','FUNC','SETCOLOR');\"> ");
	$Page->Print("<input type=button value=\"�@�m�F�@\" onclick=\"DoSubmit");
	$Page->Print("('bbs.setting','DISP','SETCOLORC');\">");
	$Page->Print("</td></tr></table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�����ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintLimitSetting
{
	my ($Page, $Sys, $Form) = @_;
	
	$Sys->Set('_TITLE', 'BBS Limitter Setting');
	
	require './module/isildur.pl';
	my $Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	# �ݒ�l���擾
	my $setResMax		= $Setting->Get('BBS_RES_MAX');
	my $setSubMax		= $Setting->Get('BBS_SUBJECT_MAX');		# �ő�X���b�h��
	my $setSubjectMax	= $Setting->Get('BBS_SUBJECT_COUNT');	# �^�C�g���ő�o�C�g��
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
	$Page->Print("<tr><td colspan=4>�e�ݒ�l����͂���[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">�^�C�g��������</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_SUBJECT_COUNT value=\"$setSubjectMax\"></td>");
	$Page->Print("<td class=\"DetailTitle\">���[��������</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MAIL_COUNT value=\"$setMailMax\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���O������</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_NAME_COUNT value=\"$setNameMax\"></td>");
	$Page->Print("<td class=\"DetailTitle\">�{��������</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_MESSAGE_COUNT value=\"$setContMax\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���X1�s�ő啶����</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_COLUMN_NUMBER value=\"$setLineLength\"></td>");
	$Page->Print("<td class=\"DetailTitle\">dat�t�@�C���ő�T�C�Y�iKB�j</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_DATMAX value=\"$setDatMax\"></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�������݉\\�s��(�����s)</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_LINE_NUMBER value=\"$setLineMax\"></td>");
	$Page->Print("<td class=\"DetailTitle\">�ő�X���b�h��(���L��=".$Sys->Get('SUBMAX').")</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_SUBJECT_MAX value=\"$setSubMax\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�������`�F�b�N</td><td>");
	$Page->Print("<input type=checkbox name=NANASHI_CHECK $setNoName value=on>�L��</td>");
	$Page->Print("<td class=\"DetailTitle\">�ő僌�X��(���L��=".$Sys->Get('RESMAX').")</td><td>");
	$Page->Print("<input type=text size=10 name=BBS_RES_MAX value=\"$setResMax\"></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">�f���������ݐ���</td><td><select name=BBS_READONLY>");
	$Page->Print("<option value=on $selROon>�ǎ��p");
	$Page->Print("<option value=caps $selROcaps>�L���b�v�̂݉\\");
	$Page->Print("<option value=none $selROnone>�������݉\\");
	$Page->Print("</select></td>");
	$Page->Print("<td class=\"DetailTitle\">DNSBL�`�F�b�N</td><td>");
	$Page->Print("<input type=checkbox name=BBS_PROXY_CHECK $setProxy value=on>�L��</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�X���b�h�쐬����(�L���b�v)</td><td>");
	$Page->Print("<input type=checkbox name=BBS_THREADCAPONLY $setCapOnly value=on>�L���b�v�̂݉\\</td>");
	$Page->Print("<td class=\"DetailTitle\">�C�O�z�X�g�K��</td><td>");
	$Page->Print("<input type=checkbox name=BBS_JP_CHECK $setOverSea value=on>�L��</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�X���b�h�쐬����(�g��)</td><td>");
	$Page->Print("<input type=checkbox name=BBS_THREADMOBILE $setThreadMb value=on>�g�т��狖��</td>");
	$Page->Print("</tr>");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>�A���������݋K��</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("����<input type=text size=5 name=timecount value=\"$setContinueMax\" style=\"text-align: right\">�������݂̂����A");
	$Page->Print("��l��<input type=text size=5 name=timeclose value=\"$setWriteMax\" style=\"text-align: right\">��܂ŏ������݉�");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>Samba�K��</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("��x�������񂾐l��<input type=text size=5 name=BBS_SAMBATIME value=\"$setSambaTime\" style=\"text-align: right\">�b(0�Ŗ���)�o���Ȃ��Ə������߂܂���B(���L��=".$Sys->Get('DEFSAMBA').")<br>");
	$Page->Print("�w��b����҂������x�������������Ƃ����ꍇ��<input type=text size=5 name=BBS_HOUSHITIME value=\"$setHoushiTime\" style=\"text-align: right\">���ԏ������݂��֎~���܂��B(���L��=".$Sys->Get('DEFHOUSHI').")");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>�X���b�h���Ă����K�� (���Ԕ�ˑ�)</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("����<input type=text size=5 name=BBS_THREAD_TATESUGI value=\"$setTateClose\" style=\"text-align: right\">�X���b�h(0�Ŗ���)�̂����A");
	$Page->Print("��l��<input type=text size=5 name=BBS_TATESUGI_COUNT2 value=\"$setTateCount2\" style=\"text-align: right\">�X���b�h�܂ŗ��Ă���");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=4>�X���b�h���Ă����K�� (���Ԉˑ�)</td></tr>");
	$Page->Print("<tr><td colspan=4>");
	$Page->Print("<input type=text size=5 name=BBS_TATESUGI_HOUR value=\"$setTateHour\" style=\"text-align: right\">����(0�Ŗ���)��");
	$Page->Print("�S�̂�<input type=text size=5 name=BBS_TATESUGI_COUNT value=\"$setTateCount\" style=\"text-align: right\">�X���b�h�܂ŗ��Ă���");
	$Page->Print("</td></tr>");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("<tr><td colspan=4 align=left><input type=button value=\"�@�ݒ�@\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETLIMIT');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���̑��ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
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
	$Page->Print("<tr><td colspan=4>�e�ݒ�l����͂���[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">ID�\\��</td><td><select name=ID_DISP>");
	$Page->Print("<option value=BBS_FORCE_ID $selIDforce>����ID");
	$Page->Print("<option value=BBS_ID_DISP $selIDdisp>�C��ID");
	$Page->Print("<option value=BBS_NO_ID $selIDnone>ID�\\������");
	$Page->Print("<option value=BBS_DISP_IP1 $selIDhost>�z�X�g�\\��");
	$Page->Print("<option value=BBS_DISP_IP2 $selIDsakhalin>���M���\\��(sakhalin)");
	$Page->Print("<option value=BBS_DISP_IP3 $selIDsiberia>���M���\\��(siberia)");
	$Page->Print("</select></td>");
	$Page->Print("<td class=\"DetailTitle\">�@�펯�ʎq(ID����)</td><td>");
	$Page->Print("<input type=checkbox name=BBS_SLIP $setIPSave value=on>�t������</td></tr>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">�j������</td><td>");
	$Page->Print("<input type=text size=20 name=BBS_YMD_WEEKS value=\"$setWeek\"></td>");
	$Page->Print("<td class=\"DetailTitle\"><s>�����Q��</s></td><td>");
	$Page->Print("<input type=checkbox name=BBS_UNICODE $setUnicode value=on>�g�p�\</td>");
	
	$Page->Print("<tr><td class=\"DetailTitle\">�g���b�v����</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_TRIPCOLUMN value=\"$setTripColumn\"></td>");
	$Page->Print("<td class=\"DetailTitle\">cookie�m�F</td><td>");
	$Page->Print("<input type=checkbox name=SUBBBS_CGI_ON $setCookie value=on>�m�F����</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index�X���b�h�v���r���[��</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_THREAD_NUMBER value=\"$setThreadNum\"></td>");
	$Page->Print("<td class=\"DetailTitle\">�@�@���Ocookie�ۑ�</td><td>");
	$Page->Print("<input type=checkbox name=BBS_NAMECOOKIE_CHECK $setNameCookie value=on>�ۑ�</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index�v���r���[���X��</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_CONTENTS_NUMBER value=\"$setContentNum\"></td>");
	$Page->Print("<td class=\"DetailTitle\">�@�@���[��cookie�ۑ�</td><td>");
	$Page->Print("<input type=checkbox name=BBS_MAILCOOKIE_CHECK $setMailCookie value=on>�ۑ�</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index���X���e�\\���s��(��)</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_INDEX_LINE_NUMBER value=\"$setContentLine\"></td>");
	$Page->Print("<td class=\"DetailTitle\">�X���b�h�쐬���</td><td>");
	$Page->Print("<input type=checkbox name=BBS_PASSWORD_CHECK $setNewThread value=on>�ʉ��</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">index���j���[��</td><td>");
	$Page->Print("<input type=text size=8 name=BBS_MAX_MENU_THREAD value=\"$setThreadMenu\"></td>");
	$Page->Print("<td class=\"DetailTitle\">�X���b�h�쐬�m�F���</td><td>");
	$Page->Print("<input type=checkbox name=BBS_NEWSUBJECT $setConfirm value=on>�m�F����</td></tr>");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("<tr><td colspan=4 align=left><input type=button value=\"�@�ݒ�@\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETOTHER');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�C���|�[�g��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$BBS	BBS���
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintSettingImport
{
	my ($Page, $SYS, $Form, $BBS) = @_;
	my (@bbsSet, $id, $name);
	
	$SYS->Set('_TITLE', 'BBS Setting Import');
	
	# ����BBS���擾
	$SYS->Get('ADMIN')->{'SECINFO'}->GetBelongBBSList($SYS->Get('ADMIN')->{'USER'}, $BBS, \@bbsSet);
	
	$Page->Print("<center><table cellspcing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\"><input type=radio name=IMPORT_KIND value=FROM_BBS");
	$Page->Print(" checked>����BBS����C���|�[�g</td>");
	$Page->Print("<td><select name=IMPORT_BBS><option value=\"\">--�f����I��--</option>");
	
	# �f���ꗗ�̏o��
	foreach $id (@bbsSet) {
		$name = $BBS->Get('NAME', $id);
		$Page->Print("<option value=$id>$name</option>\n");
	}
	
	$Page->Print("</select></td></tr>");
	$Page->Print("<tr><td valign=top class=\"DetailTitle\">");
	$Page->Print("<input type=radio name=IMPORT_KIND value=FROM_DIRECT>���ڃC���|�[�g</td>");
	$Page->Print("<td><textarea rows=10 cols=60 wrap=off name=IMPORT_DIRECT></textarea></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"�C���|�[�g\"");
	$Page->Print("onclick=\"DoSubmit('bbs.setting','FUNC','SETIMPORT');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	��{�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBaseSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = qw(BBS_SUBTITLE BBS_NONAME_NAME BBS_DELETE_NAME BBS_COOKIEPATH);
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		foreach (@inList) {
			push @$pLog, "�u$_�v���u" . $Form->Get($_) . '�v�ɐݒ�';
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
#	�J���[�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionColorSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting, $capColor);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('BBS_TITLE_COLOR', 'BBS_SUBJECT_COLOR', 'BBS_BG_COLOR', 'BBS_THREAD_COLOR',
						'BBS_MAKETHREAD_COLOR', 'BBS_MENU_COLOR', 'BBS_TEXT_COLOR', 'BBS_LINK_COLOR',
						'BBS_ALINK_COLOR', 'BBS_VLINK_COLOR', 'BBS_NAME_COLOR');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		foreach (@inList, 'BBS_CAP_COLOR') {
			push @$pLog, "�u$_�v���u" . $Form->Get($_) . '�v�ɐݒ�';
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
#	�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my $bbsLN;
		$bbsLN = $Form->Get('BBS_LINE_NUMBER') /2;
		$bbsLN = ( $bbsLN == int($bbsLN) ? $bbsLN : int($bbsLN+1) );
		$Form->Set( 'BBS_LINE_NUMBER', $bbsLN );

		my @inList = qw(BBS_SUBJECT_COUNT BBS_NAME_COUNT BBS_MAIL_COUNT BBS_MESSAGE_COUNT
						BBS_LINE_NUMBER BBS_COLUMN_NUMBER BBS_DATMAX
						timecount timeclose BBS_THREAD_TATESUGI BBS_TATESUGI_COUNT2
						BBS_TATESUGI_HOUR BBS_TATESUGI_COUNT);
		# ���͗L��
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		# �K��O����
		if (!$Form->IsNumber(\@inList)) {
			return 1002;
		}
		foreach (@inList) {
			push @$pLog, "�u$_�v���u" . $Form->Get($_) . '�v�ɐݒ�';
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
#	���̑��ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Setting);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = qw(BBS_THREAD_NUMBER BBS_CONTENTS_NUMBER BBS_INDEX_LINE_NUMBER BBS_MAX_MENU_THREAD BBS_TRIPCOLUMN);
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		foreach (@inList) {
			push @$pLog, "�u$_�v���u" . $Form->Get($_) . '�v�ɐݒ�';
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
	
	# ID�\���ݒ�
	# �������ǎd���Ȃ��ˁc
	# HOST�\��
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
#	�ݒ�C���|�[�g
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionSettingImport
{
	my ($Sys, $Form, $pLog, $BBS) = @_;
	my ($Setting, @setKeys, @importKeys, $key);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_BBSSETTING, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('IMPORT_BBS');
		
		# �����f������̃C���|�[�g���̂�
		if ($Form->Equal('IMPORT_KIND', 'FROM_BBS')) {
			# ���͗L��
			if (! $Form->IsInput(\@inList)) {
				return 1001;
			}
		}
	}
	require './module/isildur.pl';
	$Setting = ISILDUR->new;
	$Setting->Load($Sys);
	
	# import����L�[��ݒ肷��
	$Setting->GetKeySet(\@setKeys);
	foreach (@setKeys) {
		if ($_ ne 'BBS_TITLE' && $_ ne 'BBS_SUBTITLE') {
			push @importKeys, $_;
		}
	}
	
	# ����BBS����C���|�[�g
	if ($Form->Equal('IMPORT_KIND', 'FROM_BBS')) {
		my $bbs = $BBS->Get('DIR', $Form->Get('IMPORT_BBS'));
		my $baseSetting = ISILDUR->new;
		my $path = $Sys->Get('BBSPATH') . "/$bbs/SETTING.TXT";
		
		push @$pLog, "���f���u$path�v����ݒ�����C���|�[�g���܂��B";
		
		# ����BBS��SETTING.TXT��ǂݍ���
		if ($baseSetting->LoadFrom($path)) {
			# �ݒ����ݒ肷��
			foreach $key (@importKeys) {
				$Setting->Set($key, $baseSetting->Get($key));
				push @$pLog, "�@�@�u$key�v���C���|�[�g���܂����B";
			}
		}
	}
	# ���ڃC���|�[�g
	else {
		my $data = $Form->Get('IMPORT_DIRECT');
		my @datas = split(/\r\n|\r|\n/, $data);
		my (%setTemp, $line, $inKey);
		
		push @$pLog, '�����͓��e���C���|�[�g���܂��B';
		
		# �t�H�[����񂩂�ݒ���n�b�V�����쐬����
		foreach $line (@datas){
			($key, $data) = split(/=/, $line);
			$setTemp{$key} = $data;
		}
		# �ݒ����ݒ肷��
		foreach $key (keys %setTemp) {
			foreach $inKey (@importKeys) {
				if ($key eq $inKey) {
					$Setting->Set($key, $setTemp{$key});
					push @$pLog, "�@�@�u$key�v���C���|�[�g���܂����B";
				}
			}
		}
	}
	# �X�V��ۑ�
	$Setting->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
