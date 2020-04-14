unit U_TransmissorSNGPC;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, JvExMask, JvToolEdit, StdCtrls, Mask, ComCtrls, ToolWin, ImgList, sngpc, SOAPHTTPClient, AppEvnts, IniFiles, ExtCtrls, jpeg, Spin, XMLDoc, XMLIntf, U_SNGPC, U_Funcoes, InvokeRegistry,
  WSDLIntf, SOAPPasInv, SOAPHTTPPasInv, OpConvertOptions;

type
  TF_TransmissorSNGPC = class(TForm)
    ImageList: TImageList;
    TBMenu: TToolBar;
    tbEditar: TToolButton;
    tbCancelar: TToolButton;
    tbSalvar: TToolButton;
    tbSair: TToolButton;
    PCPrincipal: TPageControl;
    TSConfiguracao: TTabSheet;
    gbIdentificacao: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    eCNPJ: TMaskEdit;
    eEMail: TEdit;
    eSenha: TEdit;
    gbDiretorios: TGroupBox;
    StatusBar: TStatusBar;
    ApplicationEvents: TApplicationEvents;
    TITransmissor: TTrayIcon;
    Image1: TImage;
    Timer: TTimer;
    Label4: TLabel;
    Label5: TLabel;
    eEnvio: TJvDirectoryEdit;
    Label6: TLabel;
    eTime: TSpinEdit;
    eRequerimento: TJvDirectoryEdit;
    Label7: TLabel;
    eAmbiente: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ApplicationEventsException(Sender: TObject; E: Exception);
    procedure TITransmissorDblClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tbSairClick(Sender: TObject);
    procedure tbSalvarClick(Sender: TObject);
    procedure tbCancelarClick(Sender: TObject);
    procedure tbEditarClick(Sender: TObject);
    procedure ApplicationEventsMinimize(Sender: TObject);
    procedure ApplicationEventsRestore(Sender: TObject);
    procedure eAmbienteCloseUp(Sender: TObject);
  private
    { Private declarations }
    //Dados Conexão Servidor
    fURL:AnsiString;
    fWSDLLocation:AnsiString;
    fService:AnsiString;
    fPort:AnsiString;

    //Diretorios Comunicação
    fDIR_REQUERIMENTO:AnsiString;
    fDIR_ENVIO:AnsiString;
    fTIME:Integer;

    //Dados Autenticação
    fCNPJ:AnsiString;
    fAMBIENTE:Integer;
    fEMAIL:AnsiString;
    fSENHA:AnsiString;

    fSNGPC:TSolicitacao;
    DadosConexao: THTTPRIO;
    Concentrador: sngpcSoap;

    procedure VerificaDiretorios();
    procedure CriaARQCONFIGURACOES();
    procedure LeCONFIGURACOES();
    procedure SALVAINI();
    procedure HabilitaConfig();
    procedure SetCAMPOS();

    procedure SETVALUEDEFAULT();//Setar Propriedades para o Default

    procedure MessagemStatus(MSG:AnsiString);
    procedure ADDLOG(MSG:AnsiString);
    function GetDIRAPP: AnsiString;
    function GetDIRLOG: AnsiString;
  public
    { Public declarations }
    //Conexão
    function SetConexao():sngpcSoap;//Setar Conexão do Web-Service
    procedure CloseConexao();//Finalizar Conexão do Web-Service

    procedure Tipo_Operacao();

    property DIRETORIO_APLICACAO:AnsiString read GetDIRAPP;
    property DIRETORIO_LOG:AnsiString read GetDIRLOG;
    //Diretorios Comunicação
    property DIRETORIO_REQUERIMENTO:AnsiString read fDIR_REQUERIMENTO write fDIR_REQUERIMENTO;
    property DIRETORIO_ENVIO:AnsiString read fDIR_ENVIO write fDIR_ENVIO;
    property TIME:Integer read fTIME write fTIME default 5;
    //Dados Autenticação
    property CNPJ:AnsiString read fCNPJ write fCNPJ;
    property AMBIENTE:Integer read fAMBIENTE write fAMBIENTE default 1;
    property EMAIL:AnsiString read fEMAIL write fEMAIL;
    property SENHA:AnsiString read fSENHA write fSENHA;
    //Dados Conexão Servidor
    property URL:AnsiString read fURL write fURL;
    property WSDLLocation:AnsiString read fWSDLLocation write fWSDLLocation;
    property Service:AnsiString read fService write fService;
    property Port:AnsiString read fPort write fPort;

    property SNGPC:TSolicitacao read fSNGPC write fSNGPC;
  end;

const
  ARQ_CONFIGIGURACAO:String = 'TRANSMISSOR.INI';

var
  F_TransmissorSNGPC: TF_TransmissorSNGPC;

implementation

{$R *.dfm}

{ TF_TransmissorSNGPC }

procedure TF_TransmissorSNGPC.ADDLOG(MSG: AnsiString);
var ARQLOG:TextFile;
    NOMEARQLOG:AnsiString;
begin
  NOMEARQLOG := FormatDateTime('DDMMYYYY',Date)+'.LOG';
  AssignFile(ARQLOG,DIRETORIO_LOG + NOMEARQLOG);
  if not(FileExists(NOMEARQLOG)) then
    Rewrite(ARQLOG)
  else begin
    //Reset(ARQLOG);
    Append(ARQLOG);
  end;
  try
    Writeln(ARQLOG,DateTimeToStr(Now)+' - '+MSG);
  finally
    Flush(ARQLOG);
    CloseFile(ARQLOG);
  end;
end;

procedure TF_TransmissorSNGPC.ApplicationEventsException(Sender: TObject; E: Exception);
begin
  ADDLOG('Obj: '+Sender.ClassName+' - '+E.Message);
end;

procedure TF_TransmissorSNGPC.ApplicationEventsMinimize(Sender: TObject);
begin
  Self.Visible := False;
end;

procedure TF_TransmissorSNGPC.ApplicationEventsRestore(Sender: TObject);
begin
  Self.Visible := False;
end;

procedure TF_TransmissorSNGPC.CloseConexao;
begin
  MessagemStatus('Finalizando Conexão');
  MessagemStatus('Ativo - Aguardando Solicitação');
  DadosConexao.Free;
end;

procedure TF_TransmissorSNGPC.CriaARQCONFIGURACOES;
begin
  if not FileExists(DIRETORIO_APLICACAO+'\'+ARQ_CONFIGIGURACAO) then begin
    //Diretorios Comunicação
    DIRETORIO_REQUERIMENTO := DIRETORIO_APLICACAO+'\REQ';
    DIRETORIO_ENVIO        := DIRETORIO_APLICACAO+'\ENV';
    //Dados Conexão Servidor
    AMBIENTE     := 0;
    URL          := 'http://sngpc.anvisa.gov.br/webservice/sngpc.asmx';
    WSDLLocation := 'http://sngpc.anvisa.gov.br/webservice/sngpc.asmx?WSDL';
    Service      := 'sngpc';
    Port         := 'sngpcSoap12';
    //Dados Autenticação
    CNPJ        := '';
    EMAIL       := '';
    SENHA       := '';

    SALVAINI;
  end;
end;

procedure TF_TransmissorSNGPC.eAmbienteCloseUp(Sender: TObject);
begin
  case TComboBox(Sender).ItemIndex of
    0: begin //Produção
      URL             := 'http://homologacao.anvisa.gov.br/sngpc/webservice/sngpc.asmx';
      WSDLLocation    := 'http://homologacao.anvisa.gov.br/sngpc/webservice/sngpc.asmx?WSDL';
      Service         := 'sngpc';
      Port            := 'sngpcSoap12';
    end;
    1: begin //Homologação
      URL             := 'http://homologacao.anvisa.gov.br/sngpc/webservice/sngpc.asmx';
      WSDLLocation    := 'http://homologacao.anvisa.gov.br/sngpc/webservice/sngpc.asmx?WSDL';
      Service         := 'sngpc';
      Port            := 'sngpcSoap';
    end;
  end;
end;

procedure TF_TransmissorSNGPC.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TF_TransmissorSNGPC.FormCreate(Sender: TObject);
begin
  gbIdentificacao.Enabled := False;
  gbDiretorios.Enabled    := False;

  TITransmissor.Visible := True;

  eEnvio.InitialDir        := DIRETORIO_APLICACAO+'\ENV';
  CriaARQCONFIGURACOES();
  LeCONFIGURACOES();
  VerificaDiretorios();
  SetCAMPOS();
  MessagemStatus('Ativo - Aguardando Solicitação');

  Application.Minimize;
  Application.ShowMainForm:= False;

  Tipo_Operacao;//Verifica Tipo Operacional do Transmissor
end;

procedure TF_TransmissorSNGPC.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Case Key of
    VK_RETURN, VK_DOWN : Perform(WM_NEXTDLGCTL,0,0);
    VK_UP              : Perform(WM_NEXTDLGCTL,1,0);
  end;
  if (Key = VK_DOWN) then Key := VK_RETURN;
  if (Key = VK_UP) then Key := VK_CONTROL;
end;

function TF_TransmissorSNGPC.GetDIRAPP: AnsiString;
begin
  Result := ExtractFileDir(Application.ExeName);
end;

function TF_TransmissorSNGPC.GetDIRLOG: AnsiString;
begin
  //Diretorio de Log
  if not(DirectoryExists(DIRETORIO_APLICACAO+'\LOG\')) then
    CreateDir(DIRETORIO_APLICACAO+'\LOG\');
  Result := DIRETORIO_APLICACAO+'\LOG\';
end;

procedure TF_TransmissorSNGPC.HabilitaConfig;
begin
  tbSalvar.Enabled   := not(tbSalvar.Enabled);
  tbCancelar.Enabled := not(tbCancelar.Enabled);
  tbEditar.Enabled   := not(tbEditar.Enabled);
  tbSair.Enabled     := not(tbSair.Enabled);
  Timer.Enabled           := not(Timer.Enabled);
  gbIdentificacao.Enabled := not(gbIdentificacao.Enabled);
  gbDiretorios.Enabled    := not(gbDiretorios.Enabled);
end;

procedure TF_TransmissorSNGPC.LeCONFIGURACOES;
var ARQ_INI:TIniFile;
begin
  if FileExists(DIRETORIO_APLICACAO+'\'+ARQ_CONFIGIGURACAO) then begin
    ARQ_INI := TIniFile.Create(DIRETORIO_APLICACAO+'\'+ARQ_CONFIGIGURACAO);
    try
      //Diretorios Comunicação
      DIRETORIO_REQUERIMENTO := ARQ_INI.ReadString('DIRETORIOS','REQUERIMENTO',DIRETORIO_APLICACAO+'\REC');
      DIRETORIO_ENVIO        := ARQ_INI.ReadString('DIRETORIOS','ENVIO',DIRETORIO_APLICACAO+'\ENV');
      TIME                   := ARQ_INI.ReadInteger('DIRETORIOS','TIME',5);
      if (TIME<=2) then TIME := 5;

      //Dados Autenticação
      CNPJ            := ARQ_INI.ReadString('IDENTIFICACAO','CNPJ','');
      EMAIL           := ARQ_INI.ReadString('IDENTIFICACAO','EMAIL','');
      SENHA           := ARQ_INI.ReadString('IDENTIFICACAO','SENHA','');

      //Dados Conexão Servidor
      AMBIENTE        := ARQ_INI.ReadInteger('IDENTIFICACAO','AMBIENTE',0);
      case AMBIENTE of
        0:{$Define PRODUCAO};//Definir Ambiente de Produção
        1:{$UnDef PRODUCAO};//Definir Ambiente de Homolocação
        else {$UnDef PRODUCAO};//Definir Ambiente de Homolocação
      end;
      URL             := ARQ_INI.ReadString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'URL','http://homologacao.anvisa.gov.br/sngpc/webservice/sngpc.asmx');
      WSDLLocation    := ARQ_INI.ReadString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'WSDLLocation','http://homologacao.anvisa.gov.br/sngpc/webservice/sngpc.asmx?WSDL');
      Service         := ARQ_INI.ReadString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'Service','sngpc');
      Port            := ARQ_INI.ReadString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'Port','sngpcSoap');
    finally
      ARQ_INI.Free;
    end;
  end;
end;

procedure TF_TransmissorSNGPC.MessagemStatus(MSG: AnsiString);
begin
  Application.ProcessMessages;
  StatusBar.Panels[1].Text := MSG;
  StatusBar.Repaint;
  ADDLOG(MSG);
end;

procedure TF_TransmissorSNGPC.SALVAINI;
var ARQ_INI:TIniFile;
begin
  ARQ_INI := TIniFile.Create(DIRETORIO_APLICACAO+'\'+ARQ_CONFIGIGURACAO);
  try
    //Diretorios Comunicação
    ARQ_INI.WriteString('DIRETORIOS','REQUERIMENTO',DIRETORIO_REQUERIMENTO);
    ARQ_INI.WriteString('DIRETORIOS','ENVIO',DIRETORIO_ENVIO);
    ARQ_INI.WriteInteger('DIRETORIOS','TIME',TIME);
    //Dados Autenticação
    ARQ_INI.WriteString('IDENTIFICACAO','CNPJ',CNPJ);
    ARQ_INI.WriteString('IDENTIFICACAO','EMAIL',EMAIL);
    ARQ_INI.WriteString('IDENTIFICACAO','SENHA',SENHA);
    //Dados Conexão Servidor
    ARQ_INI.WriteInteger('IDENTIFICACAO','AMBIENTE',AMBIENTE);
    ARQ_INI.WriteString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'URL',URL);
    ARQ_INI.WriteString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'WSDLLocation',WSDLLocation);
    ARQ_INI.WriteString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'Service',Service);
    ARQ_INI.WriteString('WEBSERVICE_'+IIF(AMBIENTE=1,'HOMOLOGACAO','PRODUCAO'),'Port',Port);
  finally
    ARQ_INI.Free;
  end;
end;

procedure TF_TransmissorSNGPC.SetCAMPOS;
begin
  eCNPJ.Text  := CNPJ;
  eAmbiente.ItemIndex := AMBIENTE;
  eEMail.Text := EMAIL;
  eSenha.Text := SENHA;

  eRequerimento.Text  := DIRETORIO_REQUERIMENTO;
  eEnvio.Text         := DIRETORIO_ENVIO;
  eTime.Value         := TIME;
  Timer.Interval      := TIME*1000;//Setar Intervalos em Segundos
end;

function TF_TransmissorSNGPC.SetConexao():sngpcSoap;
begin
  MessagemStatus('Iniciando Conexão');
  if (DadosConexao=nil) then DadosConexao := THTTPRIO.Create(nil);
  try
    DadosConexao.URL          := URL;
    DadosConexao.WSDLLocation := WSDLLocation;
    DadosConexao.Service      := Service;
    DadosConexao.Port         := Port;
    case AMBIENTE of
      0: DadosConexao.Converter.Options := DadosConexao.Converter.Options + [soSOAP12];
      1: DadosConexao.Converter.Options := DadosConexao.Converter.Options - [soSOAP12];
      else DadosConexao.Converter.Options := DadosConexao.Converter.Options - [soSOAP12];
    end;
    Concentrador := DadosConexao AS sngpcSoap;
  finally
    Result := Concentrador;
  end;
end;

procedure TF_TransmissorSNGPC.SETVALUEDEFAULT;
begin
  LeCONFIGURACOES();
end;

procedure TF_TransmissorSNGPC.tbCancelarClick(Sender: TObject);
begin
  MessagemStatus('Carregando Configurações');
  LeCONFIGURACOES;
  SetCAMPOS();
  HabilitaConfig();
end;

procedure TF_TransmissorSNGPC.tbEditarClick(Sender: TObject);
begin
  HabilitaConfig();
end;

procedure TF_TransmissorSNGPC.tbSairClick(Sender: TObject);
begin
  Close;
end;

procedure TF_TransmissorSNGPC.tbSalvarClick(Sender: TObject);
begin
  if (eEnvio.Text=eRequerimento.Text) then begin
    Application.MessageBox('Diretorio de Envio deve ser Direferente do Diretorio de Recebimento!','Informação',MB_ICONINFORMATION);
    eEnvio.SetFocus;
    Abort;
  end;
  MessagemStatus('Salvando Configurações');
  CNPJ                  := eCNPJ.Text;
  EMAIL                 := eEMail.Text;
  SENHA                 := eSenha.Text;
  //AMBIENTE              := eAmbiente.ItemIndex;
  DIRETORIO_REQUERIMENTO:= eRequerimento.Text;
  DIRETORIO_ENVIO       := eEnvio.Text;
  TIME                  := eTime.Value;
  SALVAINI;
  Application.MessageBox('Configurações Salvas com Sucesso!','Informação',MB_ICONINFORMATION);
  HabilitaConfig();
end;

procedure TF_TransmissorSNGPC.TimerTimer(Sender: TObject);
begin
  Timer.Enabled := False;//Parar Chamada do Evento
  Application.ProcessMessages;
  try
    SNGPC := TSolicitacao.Create(SetConexao,CNPJ,EMAIL,SENHA,DIRETORIO_REQUERIMENTO,DIRETORIO_ENVIO);
  except
    Timer.Enabled := True;
  end;
  try
    try
      MessagemStatus('Ativo - Verificando Solicitação');
      SNGPC.ProcessaSolicitacao;
    except
      on E:Exception do begin
        ADDLOG(E.Message);
      end;
    end;
  finally
    SNGPC.Free;
    SETVALUEDEFAULT();//Setar Propriedades para o Default
    MessagemStatus('Ativo - Aguardando Solicitação');
    Timer.Enabled := True;//Reativar Chamada do Evento
  end;
end;

procedure TF_TransmissorSNGPC.Tipo_Operacao;
var OPERACAO:Integer;
    VALOR:String;
    fFile:TextFile;
begin
  if (Trim(ParamStr(1))='') then begin//Comunicação Via Troca de Arquivo
    Timer.Enabled := True;
  end
  else begin
    Timer.Enabled := False;
    //Geração Arquivo SOLICITAÇÂO
    OPERACAO := StrToIntDef(Trim(ParamStr(1)),99);
    CNPJ  := Trim(ParamStr(2));
    EMAIL := Trim(ParamStr(3));
    SENHA := Trim(ParamStr(4));
    VALOR := Trim(ParamStr(5));
    case OPERACAO of
      0: if not(FileExists(VALOR)) then OPERACAO := 99;
      1: if (Trim(VALOR)='') then OPERACAO := 99;         
    end;
    case OPERACAO of
      0,1,2: begin
        AssignFile(fFile,DIRETORIO_REQUERIMENTO+'\000000001.STS');
        try
          Rewrite(fFile);
          Writeln(fFile,CHAVE_ABERTURAARQUIVO + ' = 0');
          Writeln(fFile,CHAVE_SOLICITACAO     + ' = ' + IntToStr(OPERACAO));
          Writeln(fFile,CHAVE_IDSOLICITACAO   + ' = 1');
          Writeln(fFile,CHAVE_CNPJ            + ' = ' + CNPJ);
          Writeln(fFile,CHAVE_EMAIL           + ' = ' + EMAIL);
          Writeln(fFile,CHAVE_SENHA           + ' = ' + SENHA);
          case OPERACAO of
            0: Writeln(fFile,CHAVE_ARQUIVO_XML + ' = ' + VALOR);
            1: Writeln(fFile,CHAVE_HASH        + ' = ' + VALOR);
          end;
          Writeln(fFile,CHAVE_FINALARQUIVO    + ' = 0');
        finally
          CloseFile(fFile);
          RenameFile(DIRETORIO_REQUERIMENTO+'\000000001.STS',DIRETORIO_REQUERIMENTO+'\000000001.001')
        end;
        //processa Solicitação
        TimerTimer(Self);
      end;
    end;
    Application.Terminate;
  end;
end;

procedure TF_TransmissorSNGPC.TITransmissorDblClick(Sender: TObject);
begin
  Self.Visible := True;
  Self.BringToFront();
end;

procedure TF_TransmissorSNGPC.VerificaDiretorios;
begin
  DIRETORIO_LOG;
  //Diretorio de Envio de Mensagens
  if not(DirectoryExists(DIRETORIO_ENVIO)) then
    CreateDir(DIRETORIO_ENVIO);
  if not(DirectoryExists(DIRETORIO_REQUERIMENTO)) then
    CreateDir(DIRETORIO_REQUERIMENTO);
end;

end.
