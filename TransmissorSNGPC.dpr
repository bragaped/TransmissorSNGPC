program TransmissorSNGPC;

uses
  Forms,
  U_TransmissorSNGPC in 'U_TransmissorSNGPC.pas' {F_TransmissorSNGPC},
  sngpc in 'sngpc.pas',
  U_Funcoes in 'U_Funcoes.pas',
  U_SNGPC in 'U_SNGPC.pas',
  MD5 in 'MD5.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Transmissor SNGPC';
  Application.CreateForm(TF_TransmissorSNGPC, F_TransmissorSNGPC);
  Application.Run;
end.
