unit U_SNGPC;

interface

uses Classes, Contnrs, SysUtils, MD5, Forms, sngpc, SOAPHTTPClient, XMLDoc, XMLIntf, U_Funcoes, StrUtils, Windows;

Type
  TipoSolicitacao = (pEnvio,pConsultaEnvio,pValidaUsuario,pATIVO,pNenhuma,pSolicitacaoInvalida);

  TRetorno = Class
  private
    fXMLRETORNO : String;

    fCOD_RETORNO:Integer;
    fMENSAGEM:AnsiString;
    fHASH:AnsiString;
    fDATATRANSMISSAO:TDate;
    fDATAVALIDACAO:TDate;
    fINICIOREFERENCIA:TDate;
    fFIMREFERENCIA:TDate;

    fXMLDoc: TXMLDocument;
    fNodePri: IXMLNode;
    fNodeSec: IXMLNode;
    fNodeTer: IXMLNode;
  public
    procedure ProcessaRetorno(SOLICITACAO:TipoSolicitacao);

    property XMLRETORNO:String read fXMLRETORNO write fXMLRETORNO;
    property COD_RETORNO:Integer read fCOD_RETORNO write fCOD_RETORNO;
    property MENSAGEM:AnsiString read fMENSAGEM write fMENSAGEM;
    property HASH:AnsiString read fHASH write fHASH;
    property DATATRANSMISSAO:TDate read fDATATRANSMISSAO write fDATATRANSMISSAO;
    property DATAVALIDACAO:TDate read fDATAVALIDACAO write fDATAVALIDACAO;
    property INICIOREFERENCIA:TDate read fINICIOREFERENCIA write fINICIOREFERENCIA;
    property FIMREFERENCIA:TDate read fFIMREFERENCIA write fFIMREFERENCIA;
  End;

  TArquivo = Class
  private
    fDIR_ENVIO:AnsiString;
    fDIR_REQUERIMENTO:AnsiString;
    fFILE:TextFile;
    fNOME:AnsiString;
    fEXTENCAO:AnsiString;
    fCAMINHO:AnsiString;
    fHASH_XML:AnsiString;
    fCONTEUDO:TStringList;
    fARQUIVO_XML:String;
    function getHASH_XML: AnsiString;
    function getARQUIVO: AnsiString;
    procedure setARQUIVO(const Value: AnsiString);
    procedure setCAMINHO(const Value: AnsiString);
    function getConteudo: TStringList;
  public
    constructor Create(ADIRETORIO_ENVIO:AnsiString); overload;
    destructor Destroy; overload;
    procedure CriaArquivoTEMP();
    procedure ApagaArquivoTEMP();
    procedure AbreArquivo();
    procedure FechaArquivo();
    procedure WriteArquivo(CHAVE:AnsiString; VALOR:AnsiString);
    function ReadArquivo():AnsiString;

    property DIRETORIO_ENVIO:AnsiString read fDIR_ENVIO write fDIR_ENVIO;
    property DIRETORIO_REQUERIMENTO:AnsiString read fDIR_REQUERIMENTO write fDIR_REQUERIMENTO;
    property ARQUIVO:AnsiString read getARQUIVO write setARQUIVO;
    property CAMINHO:AnsiString read fCAMINHO write setCAMINHO;
    property NOME:AnsiString read fNOME write fNOME;
    property EXTENCAO:AnsiString read fEXTENCAO write fEXTENCAO;
    property ARQUIVO_XML:String read fARQUIVO_XML write fARQUIVO_XML;
    property HASH_XML:AnsiString read getHASH_XML write fHASH_XML;
    property CONTEUDOARQUIVO:TStringList read getConteudo;
  End;

  TSolicitacao = Class
  private
    //Concentrador
    fConcentrador: sngpcSoap;

    fSOLICITACAO: TipoSolicitacao;
    fID_SOLICITACAO: Integer;
    fCNPJ:AnsiString;
    fEMAIL:AnsiString;
    fSENHA:AnsiString;
    fDIR_REQUERIMENTO:AnsiString;
    fDIR_ENVIO:AnsiString;
    fARQUIVO:TArquivo;
    fHASH:AnsiString;
    fRETORNO:TRetorno;

    function getID_Solicitacao: Integer;
    function VerificaArquivo(DIRETORIO_REQUERIMENTO:AnsiString):AnsiString;//Verfificar se Existe Arquivo de Solicitação
    procedure ProcessaArquivo();
    procedure GRAVARETORNO();
  public
    constructor Create(ACONENTRADOR:sngpcSoap;ACNPJ:AnsiString;AEMAIL:AnsiString;ASENHA:AnsiString;
                        ADIRETORIO_REQUERIMENTO:AnsiString;ADIRETORIO_ENVIO:AnsiString); overload;
    destructor Destroy; overload;

    procedure ProcessaSolicitacao();

    property CONCENTRADOR:sngpcSoap read fConcentrador write fConcentrador;
    property SOLICITACAO:TipoSolicitacao read fSOLICITACAO write fSOLICITACAO Default pEnvio;
    property ID_SOLICITACAO: Integer read getID_Solicitacao write fID_SOLICITACAO;
    property CNPJ:AnsiString read fCNPJ write fCNPJ;
    property EMAIL:AnsiString read fEMAIL write fEMAIL;
    property SENHA:AnsiString read fSENHA write fSENHA;
    property DIRETORIO_REQUERIMENTO:AnsiString read fDIR_REQUERIMENTO write fDIR_REQUERIMENTO;
    property DIRETORIO_ENVIO:AnsiString read fDIR_ENVIO write fDIR_ENVIO;
    property ARQUIVO:TArquivo read fARQUIVO write fARQUIVO;
    property HASH:AnsiString read fHASH write fHASH;
    property RETORNO:TRetorno read fRETORNO write fRETORNO;
  End;


implementation

{ TSolicitacao }

constructor TSolicitacao.Create(ACONENTRADOR:sngpcSoap;ACNPJ:AnsiString;AEMAIL:AnsiString;ASENHA:AnsiString;
                                  ADIRETORIO_REQUERIMENTO:AnsiString;ADIRETORIO_ENVIO:AnsiString);
begin
  inherited Create;
  SOLICITACAO             := pNenhuma;
  RETORNO                 := TRetorno.Create;
  ARQUIVO                 := TArquivo.Create;
  CONCENTRADOR            := ACONENTRADOR;
  CNPJ                    := ACNPJ;
  EMAIL                   := AEMAIL;
  SENHA                   := ASENHA;
  DIRETORIO_REQUERIMENTO  := ADIRETORIO_REQUERIMENTO;
  DIRETORIO_ENVIO         := ADIRETORIO_ENVIO;

  ARQUIVO.Create(ADIRETORIO_ENVIO);
  ARQUIVO.DIRETORIO_ENVIO        := ADIRETORIO_ENVIO;
  ARQUIVO.DIRETORIO_REQUERIMENTO := ADIRETORIO_REQUERIMENTO;
  ARQUIVO.ARQUIVO := VerificaArquivo(DIRETORIO_REQUERIMENTO);
  if (ARQUIVO.ARQUIVO='') then
    SOLICITACAO := pNenhuma
  else
    ProcessaArquivo;
end;

destructor TSolicitacao.Destroy;
begin
  RETORNO.Free;
  ARQUIVO.Free;
end;

function TSolicitacao.getID_Solicitacao: Integer;
begin
  if (fID_SOLICITACAO=0) then
    fID_SOLICITACAO := Random(1000);
  Result := fID_SOLICITACAO;
end;

procedure TSolicitacao.ProcessaArquivo;
var CHAVE,VALOR:String;
    ARQUIVOABERTO,ARQUIVOFECHADO:Boolean;
    X:Integer;
begin
  //Processa Arquivo de Solicitação caso for 001 ou transmite XML
  if (ARQUIVO.EXTENCAO='001') then begin
    try
      try
        ARQUIVOABERTO := False;
        ARQUIVOFECHADO:= False;
        for X:=0 to ARQUIVO.CONTEUDOARQUIVO.Count-1 do begin
          //Separa Valores Linha
          CHAVE := Copy(ARQUIVO.CONTEUDOARQUIVO[X],1,7);
          VALOR := TrimLeft(TrimRight( Copy(ARQUIVO.CONTEUDOARQUIVO[X],Pos('=',ARQUIVO.CONTEUDOARQUIVO[X])+1,Length(ARQUIVO.CONTEUDOARQUIVO[X])) ));
          //Verifica Inicio do Arquivo
          if not(ARQUIVOABERTO) then ARQUIVOABERTO := CHAVE_ABERTURAARQUIVO=CHAVE;
          //Verifica Final do Arquivo
          if not(ARQUIVOFECHADO) then ARQUIVOFECHADO := CHAVE_FINALARQUIVO=CHAVE;
          //Apenas Faz Controle caso o Arquivo já Esteja Aberto
          if (ARQUIVOABERTO) and not(ARQUIVOFECHADO) then begin
            if (CHAVE_SOLICITACAO   = CHAVE) then SOLICITACAO     := TipoSolicitacao(StrToIntDef(VALOR,4));
            if (CHAVE_IDSOLICITACAO = CHAVE) then ID_SOLICITACAO  := StrToIntDef(VALOR,0);
            if (CHAVE_CNPJ          = CHAVE) then CNPJ            := VALOR;
            if (CHAVE_EMAIL         = CHAVE) then EMAIL           := VALOR;
            if (CHAVE_SENHA         = CHAVE) then SENHA           := VALOR;
            if (CHAVE_HASH          = CHAVE) then HASH            := VALOR;
            if (CHAVE_ARQUIVO_XML   = CHAVE) then ARQUIVO.ARQUIVO_XML := VALOR;
          end;
        end;
      finally
        //Solicitação Inválida
        if not(ARQUIVOABERTO) or not(ARQUIVOFECHADO) or (CHAVE_IDSOLICITACAO='0') then
          SOLICITACAO := pSolicitacaoInvalida;
      end;
    except
      on E:Exception do begin
        raise Exception.Create('Erro ao Realizar Leitura do Arquivo de Solicitação: '+E.Message);
        Exit;
      end;
    end;
  end;
  //Cria Arquivo Temporario
  case SOLICITACAO of
    pEnvio, pConsultaEnvio, pValidaUsuario, pATIVO: ARQUIVO.CriaArquivoTEMP;
    pNenhuma, pSolicitacaoInvalida:                 ARQUIVO.ApagaArquivoTEMP;
  end;
end;

procedure TSolicitacao.ProcessaSolicitacao;
var CONTEUDO_ARQUIVO_XML:TStringList;
begin
  Application.ProcessMessages;
  //Processamento da Solicitação
  try
    case SOLICITACAO of
      pEnvio: begin
        CONTEUDO_ARQUIVO_XML := TStringList.Create;
        try
          CONTEUDO_ARQUIVO_XML.LoadFromFile(ARQUIVO.ARQUIVO_XML);
          RETORNO.XMLRETORNO := CONCENTRADOR.EnviaArquivoSNGPC(LowerCase(EMAIL),SENHA,CONTEUDO_ARQUIVO_XML.Text,ARQUIVO.HASH_XML);//Enviar Arquivo XML
        finally
          CONTEUDO_ARQUIVO_XML.Free;
        end;
      end;
      pConsultaEnvio:       RETORNO.XMLRETORNO := CONCENTRADOR.ConsultaDadosArquivoSNGPC(LowerCase(EMAIL),SENHA,CNPJ,HASH);//Enviar Arquivo XML
      pValidaUsuario:       RETORNO.XMLRETORNO := CONCENTRADOR.ValidarUsuario(LowerCase(EMAIL),SENHA);//Solicitar Validação do Usuario e Senha
      pSolicitacaoInvalida: RETORNO.XMLRETORNO := '';//Retorno de Arquivo Inválido
      pNenhuma:             RETORNO.XMLRETORNO := '';//Nenhuma Solicitação
    end;
    if (SOLICITACAO<>pNenhuma) then
      RETORNO.ProcessaRetorno(SOLICITACAO);//Realiza Processamento do Retorno
  except
    SOLICITACAO        := pSolicitacaoInvalida;
    RETORNO.COD_RETORNO:= 99;
    RETORNO.XMLRETORNO := '';
    RETORNO.MENSAGEM   := 'Erro ao Processar Solicitação!';
  end;
  if (SOLICITACAO<>pNenhuma) then
    GRAVARETORNO();//Salvar Retorno da Solicitação
end;

procedure TSolicitacao.GRAVARETORNO;
begin
  try
    ARQUIVO.EXTENCAO := 'STS';
    ARQUIVO.AbreArquivo;//Carregar Arquivo Temporario
    ARQUIVO.WriteArquivo(CHAVE_ABERTURAARQUIVO,'0');//Abertura do Arquivo
    case SOLICITACAO of
      pEnvio:               ARQUIVO.WriteArquivo(CHAVE_SOLICITACAO,'0');//ID TIPO MENSAGEM;
      pConsultaEnvio:       ARQUIVO.WriteArquivo(CHAVE_SOLICITACAO,'1');//ID TIPO MENSAGEM;
      pValidaUsuario:       ARQUIVO.WriteArquivo(CHAVE_SOLICITACAO,'2');//ID TIPO MENSAGEM;
      pATIVO:               ARQUIVO.WriteArquivo(CHAVE_SOLICITACAO,'3');//ID TIPO MENSAGEM;
      pNenhuma:             ARQUIVO.WriteArquivo(CHAVE_SOLICITACAO,'4');//ID TIPO MENSAGEM;
      pSolicitacaoInvalida: ARQUIVO.WriteArquivo(CHAVE_SOLICITACAO,'5');//ID TIPO MENSAGEM;
    end;
    ARQUIVO.WriteArquivo(CHAVE_IDSOLICITACAO,IntToStr(ID_SOLICITACAO));//ID MENSAGEM

    //Geração de Todos os Retornos;
    if (Trim(RETORNO.HASH)>'') then
      ARQUIVO.WriteArquivo(CHAVE_HASH,RETORNO.HASH);//DATA TRANSMISSAO
    if (RETORNO.DATATRANSMISSAO>0) then
      ARQUIVO.WriteArquivo(CHAVE_DATATRANSMISSAO,DateToStr(RETORNO.DATATRANSMISSAO));//DATA TRANSMISSAO
    if (RETORNO.DATAVALIDACAO>0) then
      ARQUIVO.WriteArquivo(CHAVE_DATAVALIDACAO,DateToStr(RETORNO.DATAVALIDACAO));//DATA VALIDAÇÂO
    if (RETORNO.INICIOREFERENCIA>0) then
      ARQUIVO.WriteArquivo(CHAVE_INICIOREFERENCIA,DateToStr(RETORNO.INICIOREFERENCIA));//INICIO REFERENCIA
    if (RETORNO.FIMREFERENCIA>0) then
      ARQUIVO.WriteArquivo(CHAVE_FIMREFERENCIA,DateToStr(RETORNO.FIMREFERENCIA));//FIM REFERENCIA
    if (Trim(RETORNO.XMLRETORNO)>'') then
      ARQUIVO.WriteArquivo(CHAVE_RETORNOCOMPLETO, RETORNO.XMLRETORNO);//Retorno Completo

    ARQUIVO.WriteArquivo(CHAVE_COD_RETORNO,IntToStr(RETORNO.COD_RETORNO));//Código do Retorno;
    ARQUIVO.WriteArquivo(CHAVE_MENSAGEM_RETORNO, RETORNO.MENSAGEM);//Mensagem de Retorno
    ARQUIVO.WriteArquivo(CHAVE_FINALARQUIVO,'0');//Encerramento do Arquivo
  finally
    ARQUIVO.FechaArquivo;
  end;
end;

function TSolicitacao.VerificaArquivo(DIRETORIO_REQUERIMENTO:AnsiString): AnsiString;
begin
  Result := VerificaArquivos(DIRETORIO_REQUERIMENTO);
end;

{ TRetorno }

procedure TRetorno.ProcessaRetorno(SOLICITACAO:TipoSolicitacao);
begin
  DATATRANSMISSAO := 0;
  INICIOREFERENCIA:= 0;
  FIMREFERENCIA   := 0;
  COD_RETORNO := 999;
  MENSAGEM    := 'Arquivo Solicitação Inválido!';
  if (Trim(XMLRETORNO)='') then Exit;
  case SOLICITACAO of
    pEnvio: begin
      COD_RETORNO := 001;
      MENSAGEM    := XMLRETORNO;
      if (Pos(UpperCase('Arquivo recebido com sucesso'),UpperCase(XMLRETORNO))>0) then begin
        COD_RETORNO := 000;
        HASH        := Copy(XMLRETORNO,Length(XMLRETORNO)-19,Length(XMLRETORNO));
      end;
    end;
    pConsultaEnvio: begin
      try
        //Processar XML Retorno
        fXMLDoc := TXMLDocument.Create(Application);
        try
          fXMLDoc.LoadFromXML(XMLRETORNO);// Le conteúdo do retorno
          fXMLDoc.Active := True;
          //Pegar Dados do XML de Retorno
          fNodePri := fXMLDoc.ChildNodes.FindNode('transmissaoSNGPC');
          fNodePri.ChildNodes.First;
          fNodeSec := fNodePri.ChildNodes.FindNode('cabecalho');
          fNodeSec.ChildNodes.First;

          HASH := fNodeSec.ChildNodes['CODIGOHASH'].Text;
          DATATRANSMISSAO  := StrToDateDef(fNodeSec.ChildNodes['DATATRANSMISSAO'].Text,Date);
          INICIOREFERENCIA := StrToDateDef(fNodeSec.ChildNodes['INICIOREFERENCIA'].Text,Date);
          DATAVALIDACAO    := StrToDateDef(fNodeSec.ChildNodes['DATAVALIDACAO'].Text,0);
          FIMREFERENCIA    := StrToDateDef(fNodeSec.ChildNodes['FIMREFERENCIA'].Text,Date);
        finally
          fXMLDoc.Free;
        end;
        COD_RETORNO := 000;
        MENSAGEM    := 'Consulta Realizada Com Sucesso!';
      except
        COD_RETORNO := 900;
        MENSAGEM    := 'Retorno Inválido ou fora do padrão suportado!';
      end;
    end;
    pValidaUsuario: begin
      if (Pos('OK',UpperCase(XMLRETORNO))>0) then begin
        COD_RETORNO := 000;
        MENSAGEM    := 'Usúario Válidado com Sucesso!';
      end
      else begin
        COD_RETORNO := 001;
        MENSAGEM    := XMLRETORNO;
      end;
    end;
    pATIVO: begin
      COD_RETORNO := 000;
      MENSAGEM    := 'Transmissor Ativo!';
    end;
    pSolicitacaoInvalida: begin
      COD_RETORNO := 999;
      MENSAGEM    := 'Arquivo Solicitação Inválido!';
    end;
  end;
end;

{ TArquivo }

procedure TArquivo.AbreArquivo;
begin
  try
    if (EXTENCAO='STS') then
      CAMINHO := DIRETORIO_ENVIO;
    AssignFile(fFILE,Trim(CAMINHO+'\'+NOME+'.'+EXTENCAO));
    if (EXTENCAO='STS') then
      Rewrite(fFILE)
    else
      Reset(fFILE);
  except
    on E:Exception do begin
      raise Exception.Create('Erro ao Realizar Leitura do Arquivo de Solicitação: '+E.Message);
      Exit;
    end;
  end;
end;

procedure TArquivo.ApagaArquivoTEMP;
begin
  if not(FileExists(DIRETORIO_ENVIO+'\'+NOME+'.STS')) then begin
    DeleteFile(PChar(DIRETORIO_ENVIO+'\'+NOME+'.STS'));
  end;
end;

constructor TArquivo.Create(ADIRETORIO_ENVIO: AnsiString);
begin
  fCONTEUDO := TStringList.Create;
  DIRETORIO_ENVIO := ADIRETORIO_ENVIO;
end;

procedure TArquivo.CriaArquivoTEMP;
begin
  if not(FileExists(DIRETORIO_ENVIO+'\'+NOME+'.STS')) then begin
    try
      //Gravar Arquivo Temporario para
      try
        AssignFile(fFILE,DIRETORIO_ENVIO+'\'+NOME+'.STS');
        Rewrite(fFILE);
      finally
        CloseFile(fFILE);
      end;
    except
      on E:Exception do begin
        raise Exception.Create('Erro ao Realizar Criação do Arquivo de Retorno: '+E.Message);
      end;
    end;
  end;
end;

destructor TArquivo.Destroy;
begin
  fCONTEUDO.Free;
end;

procedure TArquivo.FechaArquivo;
var NOME_ARQUIVO:String;
begin
  CloseFile(fFILE);
  Sleep(1500);
  if MatchText(EXTENCAO,['001']) then begin
    NOME_ARQUIVO := Trim(CAMINHO+'\'+NOME+'.'+EXTENCAO);
    DeleteFile(PChar(NOME_ARQUIVO));
    if FileExists(DIRETORIO_ENVIO+'\'+NOME+'.001') then begin
      NOME_ARQUIVO := Trim(DIRETORIO_ENVIO+'\'+NOME+'.001');
      DeleteFile(PChar(NOME_ARQUIVO));
    end;
  end;
  if MatchText(EXTENCAO,['STS']) then begin
    if FileExists(DIRETORIO_ENVIO+'\'+NOME+'.001') then begin
      NOME_ARQUIVO := Trim(DIRETORIO_ENVIO+'\'+NOME+'.001');
      DeleteFile(PChar(NOME_ARQUIVO));
    end;
    RenameFile(Trim(CAMINHO+'\'+NOME+'.'+EXTENCAO),DIRETORIO_ENVIO+'\'+NOME+'.001');
  end;
end;

function TArquivo.getARQUIVO: AnsiString;
begin
  if not((CAMINHO='') or (NOME='') or (EXTENCAO='')) then
    Result := Trim(CAMINHO+'\'+NOME+'.'+EXTENCAO)
  else
    Result := '';
end;

function TArquivo.getConteudo: TStringList;
begin
  if fCONTEUDO.Count=0 then begin
    AbreArquivo;
    fCONTEUDO.Clear;
    try
      while not(Eof(fFILE)) do begin
        fCONTEUDO.Add( ReadArquivo );
      end;
    finally
      FechaArquivo;
    end;
  end;
  Result := fCONTEUDO;
end;

function TArquivo.getHASH_XML: AnsiString;
begin
  if (Trim(fHASH_XML)='') then begin
    if FileExists(ARQUIVO_XML) then
      fHASH_XML := MD5Arquivo(ARQUIVO_XML);
  end;
  Result := fHASH_XML;
end;

function TArquivo.ReadArquivo: AnsiString;
begin
  Readln(fFILE, Result);
end;

procedure TArquivo.setARQUIVO(const Value: AnsiString);
begin
  fCONTEUDO.Clear;
  if (Trim(Value)='') then begin
    CAMINHO := '';
    NOME    := '';
    EXTENCAO:= '';
  end
  else begin
    CAMINHO  := ExtractFilePath(Value);
    NOME     := Copy(Value,1,Length(Value)-4);//Pegar apenas Nome do Arquivo sem extenção
    EXTENCAO := UpperCase(Copy(Value,Length(Value)-2,Length(Value)));//Pegar apenas Nome do Arquivo sem extenção
  end;

  try
    //Apagar Caso Arquivo já exista
    if (FileExists(DIRETORIO_ENVIO+'\'+NOME+'.001')) then
      DeleteFile(PChar(DIRETORIO_ENVIO+'\'+NOME+'.001'));
    if (FileExists(DIRETORIO_ENVIO+'\'+NOME+'.STS')) then
      DeleteFile(PChar(DIRETORIO_ENVIO+'\'+NOME+'.STS'));
  except
    on E:Exception do begin
      raise Exception.Create('Erro ao deletar Arquivos de Retorno da Pasta de Destino: '+E.Message);
      Exit;
    end;
  end;
end;

procedure TArquivo.setCAMINHO(const Value: AnsiString);
begin
  if (Trim(Value)='') then
    fCAMINHO := DIRETORIO_REQUERIMENTO
  else
    fCAMINHO := Value;
end;

procedure TArquivo.WriteArquivo(CHAVE, VALOR: AnsiString);
begin
  if (Trim(VALOR)='') then Exit;
  try
    Writeln(fFILE,CHAVE + ' = ' + VALOR);//Escrever Retorno
  except
    on E:Exception do begin
      raise Exception.Create('Erro ao Escrever no Arquivo de Retorno: '+E.Message);
    end;
  end;
end;

end.
