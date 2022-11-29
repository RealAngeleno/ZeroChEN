#============================================================================================================
#
#	拡張機能 - おみくじ機能 
#	0ch_omikuji.pl
#	---------------------------------------------------------------------------
#	2005.02.19 start
#
#============================================================================================================
package ZPL_omikuji;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	オブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my		$this = shift;
	my		$obj={};
	bless($obj,$this);
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能名称取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	名称文字列
#
#------------------------------------------------------------------------------------------------------------
sub getName
{
	my	$this = shift;
	return 'おみくじ機能\';
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能説明取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	説明文字列
#
#------------------------------------------------------------------------------------------------------------
sub getExplanation
{
	my	$this = shift;
	return '名前欄に !omikuji を記入することでおみくじを行えます。';
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能タイプ取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	拡張機能タイプ(スレ立て:1,レス:2,read:4,index:8)
#
#------------------------------------------------------------------------------------------------------------
sub getType
{
	my	$this = shift;
	return (1 | 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能実行インタフェイス
#	-------------------------------------------------------------------------------------
#	@param	$sys	MELKOR
#	@param	$form	SAMWISE
#	@return	正常終了の場合は0
#
#------------------------------------------------------------------------------------------------------------
sub execute
{
	my	$this = shift;
	my	($sys,$form) = @_;
	
	if($form->Contain('FROM','!omikuji')){
		my $from = $form->Get('FROM');
		my $res = OMIKUJI(time());
		$from =~ s/!omikuji/<\/b>【$res】<b>/;
		$form->Set('FROM',$from);
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	おみくじ機能
#	-------------------------------------------------------------------------------------
#	@param	$seed	ランダムの種
#	@return	結果文字列
#
#------------------------------------------------------------------------------------------------------------
sub OMIKUJI
{
	my	($seed) = @_;
	my	(@results,$count);
	
	@results = ('大吉','中吉','小吉','吉','末吉','凶','大凶');
	$count = @results;
	
	srand($seed);
	return($results[int(rand(65535)) % $count]);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;
