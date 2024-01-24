unit MercadoPagoTEF;

interface

uses
  System.SysUtils, System.Classes,WinAPI.ShellAPI, System.Net.HttpClient,
  System.Net.URLClient, System.NetConsts,JSON,System.Generics.Collections,system.IniFiles,system.DateUtils;

const
   _BASE_URL                   : string = 'https://api.mercadopago.com';
   _TOKEN                      : string = '/oauth/token';
   _DEVICE_GET                 : string = '/point/integration-api/devices';
   _DEVICE_MODIFY              : string = '/point/integration-api/devices/{device_id}';
   _PAYMENT_CREATE             : string = '/point/integration-api/devices/{device_id}/payment-intents';
   _PAYMENT_CANCEL             : string = '/point/integration-api/devices/{device_id}/payment-intents/{payment_id}';
   _PAYMENT_GET_INTENTS        : string = '/point/integration-api/payment-intents/{payment_id}';
   _PAYMENT_LAST_STATUS        : string = '/point/integration-api/payment-intents/{payment_id}/events';
   _PAYMENT_GET_INTENTS_EVENTS : string = '/point/integration-api/payment-intents/events?startDate={dti}&endDate={dtf}';
   _PAYMENT_GET_LIST           : string = '/v1/payments/search?sort=date_created&criteria=desc&range=date_created&begin_date=NOW-{dias}DAYS&end_date=NOW';
   _PAYMENT_GET                : string = '/v1/payments/{payment_id}';
   _REFOUND_CREATE             : string = '/v1/payments/{payment_id}/refunds';
   _REFOUND_GET                : string = '/v1/payments/{payment_id}/refunds/{reembolso_id}';
   _CRIAR_LOJA_PIX             : string = '/users/{seller_id}/stores';
   _BUSCAR_LOJA_PIX            : string = '/users/{seller_id}/stores/search';
   _EXCLUIR_LOJA_PIX           : string = '/users/{seller_id}/stores/{store_id}';
   _CRIAR_CAIXA_PIX            : string = '/pos';
   _BUSCAR_CAIXA_PIX           : string = '/pos';
   _EXCLUIR_CAIXA_PIX          : string = '/pos/{caixa_id}';
   _CRIAR_PGTO_PIX             : string = '/instore/orders/qr/seller/collectors/{seller_id}/pos/{external_id}/qrs';
   _BUSCAR_PGTO_PIX            : string = '/merchant_orders/?external_reference={external_reference}';
   _BUSCAR_PGTO_PIX_DETALHADAO : string = '/v1/payments/{payment_id}';

type TmodoOperacao = (tmopPDV, tmopSTANDALONE);
type TipoCartao = (tpcardDEBITO, tbcardCREDITO);
type TipoCustoParcela = (tpcSELLER,tpcBUYER);

type TIntencaoPagamento = record
     Codigo   : Integer;
     Mensagem : String;
     IdPgto   : String;
end;

type TDevices = class
    id              : String;
    pos_id          : Integer;
    store_id        : Integer;
    external_pos_id : String;
    operating_mode  : String;
end;

type TDadosPgto = record
    Codigo         : integer;
    Mensagem       : String;
    idPagto        : string;
    idPagtoAprov   : String;
    idPagtoExtorno : string;
    Status         : String;
end;

type TBuscaPgto = record
    Codigo              : integer;
    Mensagem            : String;
    authorization_code  : string;
    transaction_details : string;
    net_received_amount : string;
    payment_method_id   : string;
    amount_taxa         : Extended;
    status              : string;
end;

type TDadosExtorno = record
    Codigo   : integer;
    Mensagem : String;
    id       : string;
    Status   : String;
end;

type TExtorno = record
    Codigo     : integer;
    Mensagem   : String;
    payment_id : string;
    amount     : Extended;
end;

type TCancelamento = record
    Codigo         : integer;
    Mensagem       : String;
    idCancelamento : String;
end;

type TListaPagamentos = class
      payment_intent_id  : string;
      external_reference : string;
      payment_method_id  : string;
      payment_type_id    : string;
      status             : string;
      status_detail      : string;

      serial_number      : string;

      first_name         : string;
      last_name          : string;
      email              : string;

      total_paid_amount  : Extended;

      id_payment         : string;
      type_payment       : string;

      date_created       : string;
      first_six_digits   : string;
      last_four_digits   : string;
      expiration_month   : string;
      expiration_year    : string;

      soft_descriptor    : string;
      id_intPayment      : string;
end;

type TDadosLoja = class
    Mensagem : string;
    id: string;
    name: string;
    date_creation: string;
    address_line: string;
    reference: string;
    latitude: Double;
    longitude: Double;
    city: string;
    state_id: string;
    external_id: string;
end;

type TdadosCaixa = class
    mensagem : String;
    image: string;
    template_document: string;
    template_image: string;
    id: string;
    status: string;
    date_created: string;
    date_last_updated: string;
    uuid: string;
    user_id: string;
    name: string;
    fixed_amount: Boolean;
    store_id: string;
    external_store_id: string;
    external_id: string;
    site: string;
    qr_code: string;
  end;

type TPgtoPIX = record
    Mensagem          : string;
    in_store_order_id : string;
    qr_data           : string;
end;

type TDadosPgtoPIX = class
    id                 : string;
    external_reference : string;
    status             : string;
    total_paid_amount  : Extended;
end;


type
  TDTMercadoPagoTEF = class(TComponent)
  private
    FRefreshToken          : String;
    FAccessToken           : String;
    FClientID              : string;
    FClientSecret          : String;
    FTGCode                : String;
    FRedirectURL           : String;
    FHabilitaControleToken : Boolean;
    FCaminhoArquivoToken   : string;
    FExpira                : TDateTime;
    FHabilitaLOG: Boolean;
    FCaminhoLOG: string;
    FUserID_SH: String;


    procedure SetAccessToken(const Value: String);
    procedure SetClientID(const Value: string);
    procedure SetClientSecret(const Value: String);
    procedure SetRedirectURL(const Value: String);
    procedure SetRefreshToken(const Value: String);
    procedure SetTGCode(const Value: String);
    procedure SetHabilitaControleToken(const Value: Boolean);
    procedure SetCaminhoArquivoToken(const Value: string);
    procedure SetExpira(const Value: TDateTime);
    procedure Log(Mensagem: string);
    function ExtrairSellerID(const str: string): string;
    procedure setUserID_SH(const Value: String);

  protected

  public
    Devices        : Tlist<TDevices>;
    IntencaoPgto   : TIntencaoPagamento;
    DadosPagamento : TDadosPgto;
    BuscaPagamento : TBuscaPgto;
    Extorno        : TDadosExtorno;
    ObterExtorno   : TExtorno;
    Cancelamento   : TCancelamento;
    ListaPagamentos: TList<TListaPagamentos>;
    DadosLoja      : TList<TDadosLoja>;
    DadosCaixa     : TList<TdadosCaixa>;
    DadosPgtoPIX   : TPgtoPIX;
    PixDetalhes    : TList<TDadosPgtoPIX>;
    procedure AutorizarAplicacao;
    function CreateAccessToken: String;
    function CreateRefreshToken: String;
    function GetDevices : TDevices;
    function ChangeOperatingMode(const ADevice: String; ModoOperacao : TmodoOperacao): String;
    function CreatePayment(const ADevice, ADescription: String; const AAmount: Double; const AInstallments: Integer; const AType: TipoCartao; const AInstallmentsCost: TipoCustoParcela; const AExternalReference: String; const APrintOnTerminal: Boolean): TIntencaoPagamento;
    function GetPaymentIntents(const APaymentIntentId: String): TDadosPgto;
    function GetPayment(const AIdPayment: String): TBuscaPgto;
    function CreateRefund(const AIdPayment: String; const AAmount: Double) : TDadosExtorno;
    function GetRefund(const AIdPayment, AIdRefund: String): TExtorno;
    function CancelPayment(const ADevice, APaymentIntentId: String): TCancelamento;
    function GetPaymentsList(const ADays: Integer): TListaPagamentos;
    function GetToken:Boolean;

    function PIXCriarLoja(NomeDaLoja, IDLoja , Endereco, numero, Cidade, UF, Latitude, Longitude, Referencia : String) : TDadosLoja;
    function PIXBuscarLojas : TDadosLoja;
    function PIXExcluirLoja(IdLoja : string) : Boolean;

    function PIXCriarCaixa(idCaixa, NomeCaixa, idLoja, IDNumberLOJA : String): TdadosCaixa;
    function PIXBuscarCaixa : TdadosCaixa;
    function PIXExcluirCaixa(IdCaixa : string) : Boolean;

    function PIXCriarPagamento(nVenda, DescricaoVenda,NomeEmpresa,external_id : string; TotalVenda : Extended ): string;
    function PIXBuscaPagamento (External_Reference : string): string;
    function PIXBuscaPagamentoDetalhado(payment_id : string) : string;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
   property ClientID              : string     read FClientID               write SetClientID;
   property ClientSecret          : String     read FClientSecret           write SetClientSecret;
   property RedirectURL           : String     read FRedirectURL            write SetRedirectURL;
   property TGCode                : String     read FTGCode                 write SetTGCode;
   property AccessToken           : String     read FAccessToken            write SetAccessToken;
   property RefreshToken          : String     read FRefreshToken           write SetRefreshToken;
   property UserID_SH             : String     read FUserID_SH              write setUserID_SH;
   property HabilitaControleToken : Boolean    read FHabilitaControleToken  write SetHabilitaControleToken;
   property CaminhoArquivoToken   : string     read FCaminhoArquivoToken    write SetCaminhoArquivoToken;
   property Expira                : TDateTime  read FExpira                 write SetExpira;
   property HabilitaLOG           : Boolean    read FHabilitaLOG            write FHabilitaLOG;
   property CaminhoLOG            : string     read FCaminhoLOG             write FCaminhoLOG;

  end;

procedure Register;

implementation

uses
  Winapi.Windows;

procedure Register;
begin
  RegisterComponents('DT Inovacao', [TDTMercadoPagoTEF]);
end;

{ TDTMercadoPagoTEF }

function TDTMercadoPagoTEF.ExtrairSellerID(const str: string): string;
var
  posHifen: Integer;
begin
  posHifen := LastDelimiter('-', str);

  if posHifen = 0 then
    Result := 'Erro: H�fen n�o encontrado'
  else
    Result := Copy(str, posHifen + 1, Length(str) - posHifen);
end;

function TDTMercadoPagoTEF.GetPaymentsList(const ADays: Integer): TListaPagamentos;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  RequestBody  : TStringStream;
  Dados        : TJSONArray;
  Obj,ObjD     : TJSONObject;
  lst          : TListaPagamentos;
  I            : Integer;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient := THTTPClient.Create;
  Dados      := TJSONArray.Create;
  Obj        := TJSONObject.Create;
  ObjD       := TJSONObject.Create;
  ListaPagamentos.Clear;

  try
    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    RequestBody := TStringStream.Create('');

    Response := HttpClient.Get( _BASE_URL + _PAYMENT_GET_LIST.Replace('{dias}', ADays.ToString) ,RequestBody,
                               TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO CONSULTAR PAYMENT LIST]');


    ObjD  := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;

    Dados := ObjD.Get('results').JsonValue as TJSONArray;

    for I := 0 to Pred( Dados.Count ) do
    begin
         Obj                    := Dados.Items[I] as TJSONObject;

         lst                    := TListaPagamentos.Create;
         lst.payment_intent_id  := Obj.GetValue('metadata.payment_intent_id').Value;
         lst.external_reference := Obj.GetValue('external_reference').Value;
         lst.payment_method_id  := Obj.GetValue('payment_method_id').Value;
         lst.payment_type_id    := Obj.GetValue('payment_type_id').Value;
         lst.status             := Obj.GetValue('status').Value;
         lst.status_detail      := Obj.GetValue('status_detail').Value;
         lst.serial_number      := Obj.GetValue('point_of_interaction.device.serial_number').Value;
         lst.first_name         := Obj.GetValue('payer.first_name').Value;
         lst.last_name          := Obj.GetValue('payer.last_name').Value;
         lst.email              := Obj.GetValue('payer.email').Value;
         lst.total_paid_amount  := StrToFloat( Obj.GetValue('transaction_details.total_paid_amount').Value.Replace('.',',') );
         lst.id_payment         := Obj.GetValue('payment_method.id').Value;
         lst.type_payment       := Obj.GetValue('payment_method.type').Value;
         lst.date_created       := Obj.GetValue('card.date_created').Value;
         lst.first_six_digits   := Obj.GetValue('card.first_six_digits').Value;
         lst.last_four_digits   := Obj.GetValue('card.last_four_digits').Value;
         lst.expiration_month   := Obj.GetValue('card.expiration_month').Value;
         lst.expiration_year    := Obj.GetValue('card.expiration_year').Value;
         lst.soft_descriptor    := Obj.GetValue('expanded.gateway.soft_descriptor').Value;
         lst.id_intPayment      := Obj.GetValue('expanded.gateway.id').Value;
         ListaPagamentos.Add(lst);
    end;

  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);
      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
end;

function TDTMercadoPagoTEF.CancelPayment(const ADevice, APaymentIntentId: String): TCancelamento;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient := THTTPClient.Create;

  try
    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Delete(_BASE_URL + _PAYMENT_CANCEL.Replace('{device_id}', ADevice).Replace('{payment_id}', APaymentIntentId),RequestBody,
                                  TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO CANCELAR PAYMENT]');

    JSONResponse                := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
    Cancelamento.idCancelamento := JSONResponse.GetValue('id').Value;
    Cancelamento.Mensagem       := Response.ContentAsString;
    Cancelamento.Codigo         := Response.StatusCode;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  RequestBody.Free;
end;

function TDTMercadoPagoTEF.GetRefund(const AIdPayment, AIdRefund: String): TExtorno;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient := THTTPClient.Create;

  try
    if AIdPayment = EmptyStr then
      raise Exception.Create('Id do Pagamento n�o informado');

    if AIdRefund = EmptyStr then
      raise Exception.Create('Id do Estorno n�o informado');

    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Get(_BASE_URL + _REFOUND_GET.Replace('{payment_id}', AIdPayment).Replace('{reembolso_id}', AIdRefund) ,RequestBody,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );
    if FHabilitaLOG then
       Log(Response.ContentAsString);


    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO CONSULTAR REEMBOLSO]');

    JSONResponse            := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
    ObterExtorno.payment_id := JSONResponse.GetValue('payment_id').Value;
    ObterExtorno.amount     := StrToFloat( JSONResponse.GetValue('amount').Value.Replace('.',',') );
    ObterExtorno.Mensagem   := Response.ContentAsString;
    ObterExtorno.Codigo     := Response.StatusCode;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  RequestBody.Free;
end;

function TDTMercadoPagoTEF.GetToken: Boolean;
var
  IniFile     : TIniFile;
  IniFilePath : string;
begin

  if FHabilitaControleToken then
  begin
        if not DirectoryExists( ExtractFilePath(FCaminhoArquivoToken) ) then
            ForceDirectories( ExtractFilePath(FCaminhoArquivoToken) );

        IniFilePath := FCaminhoArquivoToken;

        if not FileExists(IniFilePath) then
        begin
          raise Exception.Create('Arquivo INI n�o localizado');
          Exit;
        end;

        IniFile := TIniFile.Create(IniFilePath);
        try
          FClientSecret := IniFile.ReadString('Config', 'client_secret', '');
          FClientID     := IniFile.ReadString('Config', 'client_id'    , '');
          FTGCode       := IniFile.ReadString('Config', 'tgcode'       , '');
          FRedirectURL  := IniFile.ReadString('Config', 'redirect_uri' , '');
          FAccessToken  := IniFile.ReadString('Config', 'accesstoken'  , '');
          FRefreshToken := IniFile.ReadString('Config', 'refreshtoken' , '');
          FExpira       := IniFile.ReadDate(  'Config', 'expira'       , Now);
          FUserID_SH    := IniFile.ReadString('Config', 'userid'       , '');
        finally
          IniFile.Free;
        end;

        if FExpira <= Now then
          CreateRefreshToken;
  end;
end;

function TDTMercadoPagoTEF.CreateRefund(const AIdPayment: String; const AAmount: Double): TDadosExtorno;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try
    if AAmount > 0 then
      {$IFDEF VER350}
        JsonRequest.AddPair('amount', AAmount);
      {$ELSE}
        JsonRequest.AddPair('amount', TJSONNumber.Create(AAmount));//Trunc(AAmount*100));
      {$ENDIF}

    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Post(_BASE_URL + _REFOUND_CREATE.Replace('{payment_id}', AIdPayment) ,RequestBody,nil,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 201 then
      raise Exception.Create('[ERRO AO CRIAR REEMBOLSO]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     Extorno.id       := JSONResponse.GetValue('id').Value;
     Extorno.Status   := JSONResponse.GetValue('status').Value;
     Extorno.Mensagem := Response.ContentAsString;
     Extorno.Codigo   := Response.StatusCode;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;
end;

function TDTMercadoPagoTEF.GetPayment(const AIdPayment: String): TBuscaPgto;
var
  HttpClient          : THTTPClient;
  Response            : IHTTPResponse;
  RequestURL          : string;
  RequestBody         : TStringStream;
  JSONResponse        : TJSONObject;
  fee_details         : TJSONObject;
  transaction_details : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient := THTTPClient.Create;
  try
    if AIdPayment = EmptyStr then
      raise Exception.Create('Id do Pagamento n�o informado');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    RequestBody := TStringStream.Create('');

    Response := HttpClient.Get( _BASE_URL + _PAYMENT_GET.Replace('{payment_id}', AIdPayment) ,RequestBody,
                               TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );
    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO CONSULTAR PAYMENT]');

    JSONResponse                       := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
    BuscaPagamento.authorization_code  := JSONResponse.GetValue('authorization_code').Value;
    if (JSONResponse.TryGetValue<TJSONObject>('fee_details[0]', fee_details)) then
       BuscaPagamento.amount_taxa := StrToFloat( fee_details.GetValue('amount').Value.Replace('.',',') );
    transaction_details                := JSONResponse.GetValue('transaction_details') as TJSONObject;
    BuscaPagamento.net_received_amount := transaction_details.GetValue('net_received_amount').Value;
    BuscaPagamento.payment_method_id   := JSONResponse.GetValue('payment_method_id').Value;
    BuscaPagamento.status              := JSONResponse.GetValue('status').Value;
    BuscaPagamento.Codigo              := Response.StatusCode;
    BuscaPagamento.Mensagem            := Response.ContentAsString;

  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);
      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;
  HttpClient.Free;
end;

function TDTMercadoPagoTEF.GetPaymentIntents(const APaymentIntentId: String): TDadosPgto;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  payment      : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient   := THTTPClient.Create;
  try
    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    RequestBody := TStringStream.Create('');

    Response := HttpClient.Get( _BASE_URL + _PAYMENT_GET_INTENTS.Replace('{payment_id}', APaymentIntentId) ,RequestBody,
                               TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );
    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO CONSULTAR PAYMENT INTENTS]');

    JSONResponse                  := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
    if JSONResponse.GetValue('state').Value <> 'OPEN' then
    begin
        payment                       := JSONResponse.GetValue('payment') as TJSONObject;
        if JSONResponse.GetValue('state').Value <> 'CANCELED' then
        begin
             DadosPagamento.idPagto        := JSONResponse.GetValue('id').Value;
             DadosPagamento.idPagtoExtorno := JSONResponse.GetValue('id').Value;
        end else begin
             DadosPagamento.idPagto        := JSONResponse.GetValue('id').Value;
             DadosPagamento.idPagtoExtorno := '0';
        end;
        if JSONResponse.GetValue('state').Value = 'FINISHED' then
         DadosPagamento.idPagtoAprov := payment.GetValue('id').Value;
    end else begin
        DadosPagamento.idPagto        := '0';
        DadosPagamento.idPagtoExtorno := '0';
    end;
    DadosPagamento.Status         := JSONResponse.GetValue('state').Value;
    DadosPagamento.Codigo         := Response.StatusCode;
    DadosPagamento.Mensagem       := Response.ContentAsString;

  except
    on E: Exception do
    begin
        if FHabilitaLOG then
         Log(E.Message);
         raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;
  HttpClient.Free;
  RequestBody.Free;
end;

function TDTMercadoPagoTEF.CreatePayment(const ADevice, ADescription: String;
  const AAmount: Double; const AInstallments: Integer; const AType: TipoCartao;
  const AInstallmentsCost: TipoCustoParcela; const AExternalReference: String;
  const APrintOnTerminal: Boolean): TIntencaoPagamento;
var
  LJson, LPayment, LAdditionalInfo : TJSONObject;
  LHttpClient                      : THttpClient;
  RequestBody                      : TStringStream;
  LResponse                        : IHTTPResponse;
  xTipoCartao , xCustoParcela      : String;
  JSONResponse                     : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  LJson            := TJSONObject.Create;
  LPayment         := TJSONObject.Create;
  LAdditionalInfo  := TJSONObject.Create;
  JSONResponse     := TJSONObject.Create;

  case AType of
    tpcardDEBITO:  xTipoCartao := 'debit_card';
    tbcardCREDITO: xTipoCartao := 'credit_card' ;
  end;

  case AInstallmentsCost of
    tpcSELLER: xCustoParcela := 'seller';
    tpcBUYER:  xCustoParcela := 'buyer';
  end;

  try
    if (AInstallments > 1) and ((AAmount / AInstallments) < 5) then
      raise Exception.Create('Valor da parcela n�o pode ser menor que R$ 5,00');

    LJson.AddPair('amount'     , TJSONNumber.Create(AAmount));
    LJson.AddPair('description', ADescription);

    if (xTipoCartao = 'credit_card') then
    begin
      LPayment.AddPair('installments'     , TJSONNumber.Create(AInstallments));
      LPayment.AddPair('installments_cost', TJSONString.Create(xCustoParcela));
    end;

    LPayment.AddPair('type'                     , xTipoCartao);
    LJson.AddPair('payment'                     , LPayment);
    LAdditionalInfo.AddPair('external_reference', AExternalReference);
    LAdditionalInfo.AddPair('print_on_terminal' , TJSONBool.Create(APrintOnTerminal));
    LJson.AddPair('additional_info'             , LAdditionalInfo);

    RequestBody := TStringStream.Create(LJson.ToString);

    LHttpClient             := THttpClient.Create;
    LHttpClient.ContentType := 'application/json';

    LResponse := LHttpClient.Post(_BASE_URL + _PAYMENT_CREATE.Replace('{device_id}', ADevice) ,RequestBody,nil,
                                  TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );
    if FHabilitaLOG then
       Log(LResponse.ContentAsString);

    if LResponse.StatusCode <> 201 then
      raise Exception.Create('[ERRO AO CRIAR PAYMENT]');

    JSONResponse    := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
    IntencaoPgto.IdPgto   := JSONResponse.GetValue('id').Value;
    IntencaoPgto.Codigo   := LResponse.StatusCode;
    IntencaoPgto.Mensagem := LResponse.ContentAsString;
  except
    on E: Exception do
    begin
        if FHabilitaLOG then
         Log(E.Message);
         raise Exception.Create(E.Message + sLineBreak + LResponse.ContentAsString);
    end;
  end;

  LJson.Free;
  LHttpClient.Free;
  RequestBody.Free;
end;


function TDTMercadoPagoTEF.ChangeOperatingMode(const ADevice: String; ModoOperacao : TmodoOperacao): String;
var
  LResponse   : IHTTPResponse;
  LClient     : THTTPClient;
  LJson       : TJSONObject;
  RequestBody : TStringStream;
  xModo       : String;
begin
   if FHabilitaControleToken then
       GetToken;

  Result      := EmptyStr;
  LClient     := THTTPClient.Create;
  LJson       := TJSONObject.Create;
  RequestBody := TStringStream.Create;

  case ModoOperacao of
    tmopPDV:        xModo := '{"operating_mode": "PDV"}';
    tmopSTANDALONE: xModo := '{"operating_mode": "STANDALONE"}';
  end;

  try
    RequestBody := TStringStream.Create(xModo);

    LResponse := LClient.Patch(_BASE_URL + _DEVICE_MODIFY.Replace('{device_id}',ADevice), RequestBody, nil,
                               TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if LResponse.StatusCode <> 200 then
    begin
      if FHabilitaLOG then
       Log(LResponse.ContentAsString);
      raise Exception.Create('[ERRO AO MODIFICAR OPERATION MODE]');
    end;

    if FHabilitaLOG then
       Log(LResponse.ContentAsString);

    Result := LResponse.ContentAsString;
  except
    on E: Exception do
    begin
        if FHabilitaLOG then
         Log(E.Message);
         raise Exception.Create(E.Message + sLineBreak + LResponse.ContentAsString);
    end;
  end;

  LClient.Free;
  LJson.Free;
end;

function TDTMercadoPagoTEF.GetDevices: TDevices;
var
  LResponse   : IHTTPResponse;
  LClient     : THTTPClient;
  RequestBody : TStringStream;
  Device      : TDevices;
  JSONArray   : TJSONArray;
  JSONObject  : TJSONObject;
  I           : integer;
  obj         : TJsonObject;
begin
  LClient     := THTTPClient.Create;
  JSONArray   := TJSONArray.Create;
  Devices.Clear;
  try
     if FHabilitaControleToken then
       GetToken;

     LClient.ContentType := 'application/json';
     LClient.Accept      := '/';

     RequestBody  := TStringStream.Create('');

      try
        LResponse := LClient.Get( _BASE_URL + _DEVICE_GET, RequestBody,
                                 TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

          if LResponse.StatusCode <> 200 then
          raise Exception.Create('[ERRO AO LER DEVICES]');

          JSONObject := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
          JSONArray  := JSONObject.GetValue('devices') as TJSONArray;

          for I := 0 to Pred( JSONArray.Count ) do
          begin
                obj                    := TJsonObject.ParseJSONValue(JSONArray.Items[I].ToString) as TJsonObject;

                Device                 := TDevices.Create;
                Device.id              := obj.GetValue('id').Value;
                Device.pos_id          := obj.GetValue('pos_id').Value.ToInteger;
                Device.store_id        := obj.GetValue('store_id').Value.ToInteger;
                Device.external_pos_id := obj.GetValue('external_pos_id').Value;
                Device.operating_mode  := obj.GetValue('operating_mode').Value;

                Devices.Add(Device);
          end;

          if FHabilitaLOG then
          Log(LResponse.ContentAsString);
      except
        on E: Exception do
        begin
        if FHabilitaLOG then
         Log(E.Message);
         raise Exception.Create(E.Message + sLineBreak + LResponse.ContentAsString);
        end;
      end;
      LClient.Free;
  finally

  end;
end;

procedure TDTMercadoPagoTEF.AutorizarAplicacao;
var
Handle : HWND;
begin
    ShellExecute(Handle,
                 'open',
                 PChar('https://auth.mercadopago.com.br/authorization?client_id='+ FClientID +
                 '&response_type=code&platform_id=mp&state=RANDOM_ID&redirect_uri='+ FRedirectURL +'')
                 ,nil
                 ,nil
                 ,SW_SHOWMAXIMIZED);
end;

constructor TDTMercadoPagoTEF.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Devices         := Tlist<TDevices>.Create;
  ListaPagamentos := TList<TListaPagamentos>.Create;
  DadosLoja       := TList<TDadosLoja>.Create;
  DadosCaixa      := TList<TdadosCaixa>.Create;
  PixDetalhes     := TList<TDadosPgtoPIX>.create;
end;

function TDTMercadoPagoTEF.CreateAccessToken: String;
var
  LResponse    : IHTTPResponse;
  LParams      : TStringList;
  LClient      : THTTPClient;
  JSONResponse : TJSONObject;
  IniFilePath  : String;
  IniFile      : TIniFile;
begin
  Result  := EmptyStr;
  LClient := THTTPClient.Create;
  LParams := TStringList.Create;
  try
    LParams.Add('grant_type=authorization_code');
    LParams.Add('client_secret=' + FClientSecret);
    LParams.Add('client_id='     + FClientID);
    LParams.Add('code='          + FTGCode);
    LParams.Add('redirect_uri='  + FRedirectURL);

    LResponse := LClient.Post(_BASE_URL + _TOKEN, LParams);

    if LResponse.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO GERAR TOKEN]');

    JSONResponse  := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
    FAccessToken  := JSONResponse.GetValue('access_token').Value;
    FRefreshToken := JSONResponse.GetValue('refresh_token').Value;

    if FHabilitaControleToken then
    begin
          if not DirectoryExists( ExtractFilePath(FCaminhoArquivoToken) ) then
            ForceDirectories( ExtractFilePath(FCaminhoArquivoToken) );

          IniFilePath := FCaminhoArquivoToken;

          IniFile := TIniFile.Create(IniFilePath);
          try
            IniFile.WriteString('Config', 'client_secret', FClientSecret);
            IniFile.WriteString('Config', 'client_id'    , FClientID);
            IniFile.WriteString('Config', 'tgcode'       , FTGCode);
            IniFile.WriteString('Config', 'redirect_uri' , FRedirectURL);
            IniFile.WriteString('Config', 'accesstoken'  , FAccessToken);
            IniFile.WriteString('Config', 'refreshtoken' , FRefreshToken);
            IniFile.WriteDate(  'Config', 'expira'       , IncDay(now,179));
            IniFile.WriteString('Config', 'userid'       , FUserID_SH);
          finally
            IniFile.Free;
          end;
    end;

    if FHabilitaLOG then
     Log(LResponse.ContentAsString);

    Result := LResponse.ContentAsString;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
         Log(E.Message);
      raise Exception.Create(E.Message + sLineBreak + LResponse.ContentAsString);
    end;
  end;
  LClient.Free;
  LParams.Free;
end;

procedure TDTMercadoPagoTEF.Log(Mensagem: string);
var
  NomeArquivo: string;
  Arquivo: TextFile;
begin
    try
        try
           if FHabilitaLOG then
           begin
                if CaminhoLog<>'' then
                begin
                    if not DirectoryExists(FCaminhoLog) then
                        ForceDirectories(FCaminhoLog);
                    NomeArquivo := ChangeFileExt(FCaminhoLog, '\LogMercadoPago_' + FormatDateTime('DD_MM_YYYY',Date)+'.log');
                    AssignFile(Arquivo, NomeArquivo);
                    if FileExists(NomeArquivo) then
                      Append(arquivo)
                    else
                      ReWrite(arquivo);
                    try
                      WriteLn(arquivo, 'Data: '+ DateTimeToStr(Now));
                      WriteLn(arquivo, 'Result: ' + Mensagem );
                      WriteLn(arquivo, '------------------------------------------- ');
                    finally
                      CloseFile(arquivo);
                    end;
                end;
           end;
        except
        end;
    finally
    end;
end;

function TDTMercadoPagoTEF.PIXBuscaPagamento(External_Reference : string): string;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  lc           : TdadosCaixa;
  JSONArray    : TJSONArray;
  i ,x         : integer;
  pgto         : TDadosPgtoPIX;
  obj,obj2     : TJSONObject;
  JSONArr      : TJSONArray;
  OK           : Boolean;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try
    ok                     := False;
    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Get(_BASE_URL + _BUSCAR_PGTO_PIX.Replace('{external_reference}', External_Reference),RequestBody,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO BUSCAR CAIXA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     JSONArray        := JSONResponse.GetValue('elements') as TJSONArray;

     PixDetalhes.Clear;

     for I := 0 to Pred( JSONArray.Count ) do
     begin
         ok      := False;
         obj     := TJsonObject.ParseJSONValue(JSONArray.Items[I].ToString) as TJsonObject;
         JSONArr := obj.GetValue('payments') as TJSONArray;

         pgto                    := TDadosPgtoPIX.Create;
         pgto.id                 := obj.GetValue('id').Value;
         pgto.external_reference := obj.GetValue('external_reference').Value;
         for x := 0 to Pred( JSONArr.Count ) do
         begin
              obj2                    := TJsonObject.ParseJSONValue(JSONArr.Items[x].ToString) as TJsonObject;
              pgto.id                 := obj2.GetValue('id').Value;
              pgto.status             := obj2.GetValue('status').Value;
              pgto.total_paid_amount  := StrToFloat(obj2.GetValue('total_paid_amount').Value.Replace('.',','));
              OK                      := True;
         end;

         if not ok then
         begin
            pgto.status             := 'no';
            pgto.total_paid_amount  := 0;
         end;

         PixDetalhes.Add(pgto);
     end;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXBuscaPagamentoDetalhado(
  payment_id: string): string;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  lc           : TdadosCaixa;
  JSONArray    : TJSONArray;
  i ,x         : integer;
  pgto         : TDadosPgtoPIX;
  obj          : TJSONObject;
  JSONArr      : TJSONArray;
  OK           : Boolean;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Get(_BASE_URL + _BUSCAR_PGTO_PIX_DETALHADAO.Replace('{payment_id}',payment_id),RequestBody,
                               TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO BUSCAR CAIXA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     Result           := Response.ContentAsString;

  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXBuscarCaixa: TdadosCaixa;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  lc           : TdadosCaixa;
  JSONArray    : TJSONArray;
  i            : integer;
  obj, obj2    : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Get(_BASE_URL + _BUSCAR_CAIXA_PIX,RequestBody,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO BUSCAR CAIXA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     JSONArray        := JSONResponse.GetValue('results') as TJSONArray;

     DadosCaixa.Clear;

     for I := 0 to Pred( JSONArray.Count ) do
     begin
         obj                  := TJsonObject.ParseJSONValue(JSONArray.Items[I].ToString) as TJsonObject;
         obj2                 := obj.GetValue('qr') as TJSONObject;

         lc                   := TdadosCaixa.Create;
         lc.Mensagem          := Response.ContentAsString;
         lc.image             := obj2.GetValue('image').Value;
         lc.template_document := obj2.GetValue('template_document').Value;
         lc.template_image    := obj2.GetValue('template_image').Value;
         lc.id                := obj.GetValue('id').Value;
         lc.date_created      := obj.GetValue('date_created').Value;
         lc.date_last_updated := obj.GetValue('date_last_updated').Value;
         lc.user_id           := obj.GetValue('user_id').Value;
         lc.name              := obj.GetValue('name').Value;
         if obj.TryGetValue('store_id', lc.store_id) then
         lc.store_id          := obj.GetValue('store_id').Value;

         DadosCaixa.Add(lc);
     end;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXBuscarLojas: TDadosLoja;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  JSONArray    : TJSONArray;
  lj           : TDadosLoja;
  i            : Integer;
  obj,obj2     : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try
    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Get(_BASE_URL + _BUSCAR_LOJA_PIX.Replace('{seller_id}', ExtrairSellerID(FTGCode)) ,nil,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO BUSCAR LOJA]');

      JSONResponse := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      JSONArray := JSONResponse.GetValue('results') as TJSONArray;

      DadosLoja.Clear;

      for I := 0 to Pred( JSONArray.Count ) do
      begin
           obj              := TJsonObject.ParseJSONValue(JSONArray.Items[I].ToString) as TJsonObject;
           obj2             := obj.GetValue('location') as TJSONObject;
           lj               := TDadosLoja.Create;
           lj.id            := obj.GetValue('id').Value;
           lj.name          := obj.GetValue('name').Value;
           lj.date_creation := obj.GetValue('date_creation').Value;
           lj.address_line  := obj2.GetValue('address_line').Value;
           lj.reference     := obj2.GetValue('reference').Value;
           lj.latitude      := StrToFloat( obj2.GetValue('latitude').Value.Replace('.',',') );
           lj.longitude     := StrToFloat( obj2.GetValue('longitude').Value.Replace('.',',') );
           if obj2.TryGetValue('city', lj.city) then
           lj.city          := obj2.GetValue('city').Value;
           if obj2.TryGetValue('state_id', lj.state_id) then
           lj.state_id      := obj2.GetValue('state_id').Value;
           if JSONArray[i].TryGetValue<String>('external_id', lj.external_id) then
           lj.external_id   := obj.GetValue('external_id').Value;

           DadosLoja.Add(lj);
      end;

  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXCriarCaixa(idCaixa, NomeCaixa, idLoja,
  IDNumberLOJA : String): TdadosCaixa;
const JsonBody =  ' { ' +
                  ' "category":null, ' +
                  ' "external_id":"%s", ' +
                  ' "external_store_id":"%s", ' +
                  ' "fixed_amount":false, ' +
                  ' "name":"%s", ' +
                  ' "store_id":"%s" ' +
                  ' } ';
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  lc           : TdadosCaixa;
  obj,obj2     : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create(Format(JsonBody,[idCaixa, idLoja, NomeCaixa, IDNumberLOJA]));

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Post(_BASE_URL + _CRIAR_CAIXA_PIX,RequestBody,nil,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 201 then
      raise Exception.Create('[ERRO AO CRIAR CAIXA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     obj2             := JSONResponse.GetValue('qr') as TJSONObject;

     DadosCaixa.Clear;

     lc                   := TdadosCaixa.Create;
     lc.Mensagem          := Response.ContentAsString;
     lc.image             := obj2.GetValue('image').Value;
     lc.template_document := obj2.GetValue('template_document').Value;
     lc.template_image    := obj2.GetValue('template_image').Value;
     lc.id                := JSONResponse.GetValue('id').Value;
     lc.status            := JSONResponse.GetValue('status').Value;
     lc.date_created      := JSONResponse.GetValue('date_created').Value;
     lc.date_last_updated := JSONResponse.GetValue('date_last_updated').Value;
     lc.uuid              := JSONResponse.GetValue('uuid').Value;
     lc.user_id           := JSONResponse.GetValue('user_id').Value;
     lc.name              := JSONResponse.GetValue('name').Value;
     lc.store_id          := JSONResponse.GetValue('store_id').Value;
     lc.external_id       := JSONResponse.GetValue('external_id').Value;
     lc.site              := JSONResponse.GetValue('site').Value;
     lc.qr_code           := JSONResponse.GetValue('qr_code').Value;

     DadosCaixa.Add(lc);
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXCriarLoja(NomeDaLoja, IDLoja, Endereco, numero,
  Cidade, UF, Latitude, Longitude, Referencia: String): TDadosLoja;
const JsonBody =  '{' +
                  '"external_id": "%s",' +
                  '"location": {' +
                  '"street_number": "%s",' +
                  '"street_name": "%s",' +
                  '"city_name": "%s",' +
                  '"state_name": "%s",' +
                  '"latitude": %s,' +
                  '"longitude": %s,' +
                  '"reference": "%s"' +
                  '}, ' +
                  '"name": "%s"}';
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
  lj           : TDadosLoja;
  obj2         : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create(Format(JsonBody,[IDLoja, numero, Endereco, Cidade, UF, Latitude, Longitude, Referencia, NomeDaLoja]));

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Post(_BASE_URL + _CRIAR_LOJA_PIX.Replace('{seller_id}', ExtrairSellerID(FTGCode)) ,RequestBody,nil,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 201 then
      raise Exception.Create('[ERRO AO CRIAR LOJA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     obj2             := JSONResponse.GetValue('location') as TJSONObject;

     DadosLoja.Clear;

     lj               := TDadosLoja.Create;
     lj.Mensagem      := Response.ContentAsString;
     lj.id            := JSONResponse.GetValue('id').Value;
     lj.name          := JSONResponse.GetValue('name').Value;
     lj.date_creation := JSONResponse.GetValue('date_creation').Value;
     lj.address_line  := obj2.GetValue('address_line').Value;
     lj.reference     := obj2.GetValue('reference').Value;
     lj.latitude      := StrToFloat( obj2.GetValue('latitude').Value.Replace('.',',') );
     lj.longitude     := StrToFloat( obj2.GetValue('longitude').Value.Replace('.',',') );
     lj.city          := obj2.GetValue('city').Value;
     lj.state_id      := obj2.GetValue('state_id').Value;
     lj.external_id   := JSONResponse.GetValue('external_id').Value;

     DadosLoja.Add(lj);
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXCriarPagamento(nVenda, DescricaoVenda,NomeEmpresa,external_id : string; TotalVenda : Extended ): string;
const
  JsonBody =
    '{' +
      '"cash_out": {' +
        '"amount":0' +
      '},' +
      '"external_reference":"%s",' +
      '"description":"%s",' +
      '"items": [' +
        '{' +
          '"sku_number":"1",' +
          '"category":"Venda CashBox",' +
          '"title":"Venda CashBox",' +
          '"description":"Venda CashBox",' +
          '"unit_measure":"Unidade",' +
          '"quantity":1,' +
          '"unit_price":%s,' +
          '"total_amount":%s ' +
        '}' +
      '],' +
      '"notification_url":null,' +
      '"expiration_date":"%s",' +
      '"sponsor": {' +
        '"id":%s' +
      '},' +
      '"title":"%s",' +
      '"total_amount":%s ' +
    '}';


var
  xItensJson        : string;
  HttpClient        : THTTPClient;
  Response          : IHTTPResponse;
  RequestURL        : string;
  JsonRequest       : TJSONObject;
  RequestBody       : TStringStream;
  JSONResponse      : TJSONObject;
  lj                : TDadosLoja;
  CurrentDateTime   : TDateTime;
  FormattedDateTime : string;
begin
  CurrentDateTime   := Now;
  CurrentDateTime   := IncMinute(CurrentDateTime, 5);
  FormattedDateTime := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz-04:00', CurrentDateTime);

   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create(Format(JsonBody,[nVenda, DescricaoVenda, TotalVenda.ToString.Replace('.','').Replace(',','.'), TotalVenda.ToString.Replace('.','').Replace(',','.'), FormattedDateTime, FUserID_SH ,DescricaoVenda,TotalVenda.ToString.Replace('.','').Replace(',','.') ]));

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Post(_BASE_URL + _CRIAR_PGTO_PIX.Replace('{seller_id}', ExtrairSellerID(FTGCode)).Replace('{external_id}',external_id ) ,RequestBody,nil,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 201 then
      raise Exception.Create('[ERRO AO CRIAR PAGTO PIX]');

     JSONResponse                   := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
     DadosPgtoPIX.Mensagem          := Response.ContentAsString;
     DadosPgtoPIX.in_store_order_id := JSONResponse.GetValue('in_store_order_id').value;
     DadosPgtoPIX.qr_data           := JSONResponse.GetValue('qr_data').value;

  except
    on E: Exception do
    begin
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXExcluirCaixa(IdCaixa: string): Boolean;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Delete(_BASE_URL + _EXCLUIR_CAIXA_PIX.Replace('{caixa_id}', IdCaixa) ,RequestBody,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 204 then
      raise Exception.Create('[ERRO AO EXCLUIR CAIXA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;

     Result           := True;

  except
    on E: Exception do
    begin
      Result := False;
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.PIXExcluirLoja(IdLoja: string): Boolean;
var
  HttpClient   : THTTPClient;
  Response     : IHTTPResponse;
  RequestURL   : string;
  JsonRequest  : TJSONObject;
  RequestBody  : TStringStream;
  JSONResponse : TJSONObject;
begin
   if FHabilitaControleToken then
       GetToken;

  HttpClient  := THTTPClient.Create;
  JsonRequest := TJSONObject.Create;

  try

    RequestBody            := TStringStream.Create('');

    HttpClient             := THttpClient.Create;
    HttpClient.ContentType := 'application/json';

    Response := HttpClient.Delete(_BASE_URL + _EXCLUIR_LOJA_PIX.Replace('{seller_id}', ExtrairSellerID(FTGCode)).Replace('{store_id}', IdLoja) ,RequestBody,
                                TNetHeaders.Create(TNameValuePair.Create('Authorization', 'Bearer ' + FAccessToken)) );

    if FHabilitaLOG then
       Log(Response.ContentAsString);

    if Response.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO EXCLUIR LOJA]');

     JSONResponse     := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;

     Result           := True;

  except
    on E: Exception do
    begin
      Result := False;
      if FHabilitaLOG then
       Log(E.Message);

      if Response = nil then
        raise Exception.Create(E.Message)
      else
        raise Exception.Create(E.Message + sLineBreak + Response.ContentAsString);
    end;
  end;

  HttpClient.Free;
  JsonRequest.Free;
  RequestBody.Free;

end;

function TDTMercadoPagoTEF.CreateRefreshToken: String;
var
  LResponse    : IHTTPResponse;
  LParams      : TStringList;
  LClient      : THTTPClient;
  JSONResponse : TJSONObject;
  IniFilePath  : String;
  IniFile      : TIniFile;
begin
  Result  := EmptyStr;
  LClient := THTTPClient.Create;
  LParams := TStringList.Create;
  try
    LParams.Add('grant_type=refresh_token');
    LParams.Add('client_secret=' + FClientSecret);
    LParams.Add('client_id='     + FClientID);
    LParams.Add('refresh_token=' + FRefreshToken);

    LResponse := LClient.Post(_BASE_URL + _TOKEN, LParams);

    if LResponse.StatusCode <> 200 then
      raise Exception.Create('[ERRO AO ATUALIZAR TOKEN]');

    JSONResponse  := TJSONObject.ParseJSONValue(LResponse.ContentAsString) as TJSONObject;
    FAccessToken  := JSONResponse.GetValue('access_token').Value;
    FRefreshToken := JSONResponse.GetValue('refresh_token').Value;

    if FHabilitaControleToken then
    begin
          if not DirectoryExists( ExtractFilePath(FCaminhoArquivoToken) ) then
            ForceDirectories( ExtractFilePath(FCaminhoArquivoToken) );

          IniFilePath := FCaminhoArquivoToken;

          IniFile := TIniFile.Create(IniFilePath);
          try
            IniFile.WriteString('Config', 'client_secret', FClientSecret);
            IniFile.WriteString('Config', 'client_id'    , FClientID);
            IniFile.WriteString('Config', 'tgcode'       , FTGCode);
            IniFile.WriteString('Config', 'redirect_uri' , FRedirectURL);
            IniFile.WriteString('Config', 'accesstoken'  , FAccessToken);
            IniFile.WriteString('Config', 'refreshtoken' , FRefreshToken);
            IniFile.WriteDate(  'Config', 'expira'       , IncDay(now,179));
            IniFile.WriteString('Config', 'userid'       , FUserID_SH);
          finally
            IniFile.Free;
          end;
    end;

    if FHabilitaLOG then
     Log(LResponse.ContentAsString);

    Result := LResponse.ContentAsString;
  except
    on E: Exception do
    begin
      if FHabilitaLOG then
         Log(E.Message);
      raise Exception.Create(E.Message + sLineBreak + LResponse.ContentAsString);
    end;
  end;
  LClient.Free;
  LParams.Free;
end;

destructor TDTMercadoPagoTEF.Destroy;
begin
  Devices.Clear;
  ListaPagamentos.Clear;
  DadosLoja.Clear;
  DadosCaixa.Clear;
  PixDetalhes.Clear;

  FreeAndNil(Devices);
  FreeAndNil(ListaPagamentos);
  FreeAndNil(DadosLoja);
  FreeAndNil(DadosCaixa);
  FreeAndNil(PixDetalhes);

  inherited Destroy;
end;

procedure TDTMercadoPagoTEF.SetAccessToken(const Value: String);
begin
  FAccessToken := Value;
end;

procedure TDTMercadoPagoTEF.SetCaminhoArquivoToken(const Value: string);
begin
  FCaminhoArquivoToken := Value;
end;

procedure TDTMercadoPagoTEF.SetClientID(const Value: string);
begin
  FClientID := Value;
end;

procedure TDTMercadoPagoTEF.SetClientSecret(const Value: String);
begin
  FClientSecret := Value;
end;

procedure TDTMercadoPagoTEF.SetExpira(const Value: TDateTime);
begin
  FExpira := Value;
end;

procedure TDTMercadoPagoTEF.SetHabilitaControleToken(const Value: Boolean);
begin
  FHabilitaControleToken := Value;
end;

procedure TDTMercadoPagoTEF.SetRedirectURL(const Value: String);
begin
  FRedirectURL := Value;
end;

procedure TDTMercadoPagoTEF.SetRefreshToken(const Value: String);
begin
  FRefreshToken := Value;
end;

procedure TDTMercadoPagoTEF.SetTGCode(const Value: String);
begin
  FTGCode := Value;
end;

procedure TDTMercadoPagoTEF.setUserID_SH(const Value: String);
begin
  FUserID_SH := Value;
end;

end.







