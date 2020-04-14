unit U_Funcoes;

interface

uses SysUtils;

function IIF(Condicao:Boolean; ResultTrue:String; ResultFalse:String):String;

procedure DeleteArquivos(Diretorio:String;Extencao:String);
function VerificaArquivos(Diretorio:AnsiString):AnsiString;

const
  CHAVE_ABERTURAARQUIVO : String = '000-000';

  CHAVE_SOLICITACAO     : String = '001-000';
  CHAVE_IDSOLICITACAO   : String = '002-000';
  CHAVE_CNPJ            : String = '003-000';
  CHAVE_EMAIL           : String = '004-000';
  CHAVE_SENHA           : String = '005-000';
  CHAVE_HASH            : String = '006-000';
  CHAVE_ARQUIVO_XML     : String = '007-000';

  CHAVE_DATATRANSMISSAO : String = '105-000';
  CHAVE_INICIOREFERENCIA: String = '106-000';
  CHAVE_FIMREFERENCIA   : String = '107-000';
  CHAVE_DATAVALIDACAO   : String = '108-000';

  CHAVE_RETORNOCOMPLETO : String = '800-000';

  CHAVE_COD_RETORNO     : String = '900-000';
  CHAVE_MENSAGEM_RETORNO: String = '900-001';

  CHAVE_FINALARQUIVO    : String = '999-000';

implementation

function IIF(Condicao:Boolean; ResultTrue:String; ResultFalse:String):String;
begin
  if Condicao then
    Result := ResultTrue
  else
    Result := ResultFalse;
end;

procedure DeleteArquivos(Diretorio:String;Extencao:String);
var I:Integer;
    SR: TSearchRec;
begin
  if (Extencao='*') then Exit;
  if (Diretorio='C') or (Diretorio='c') or (Diretorio='D') or (Diretorio='D') then
    Diretorio := UpperCase(Diretorio)+':';
  if Copy(Diretorio,Length(Diretorio)-1,1)='\' then
    Diretorio := Copy(Diretorio,0,Length(Diretorio)-1);
  I := FindFirst(Diretorio+'\*.'+Extencao, faAnyFile, SR);
  while I = 0 do begin
    DeleteFile(Diretorio+'\'+SR.Name);
    I := FindNext(SR);
  end;
end;

function VerificaArquivos(Diretorio:AnsiString):AnsiString;
var I:Integer;
    SR: TSearchRec;
begin
  Result := '';
  I := FindFirst(Diretorio+'\*.001', faAnyFile, SR);
  while I = 0 do begin
    Result := SR.Name;
    if Result='' then
      I := FindNext(SR)
    else
      I := 1;
  end;
end;

end.
