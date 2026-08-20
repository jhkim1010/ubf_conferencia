// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Mana';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Usar o idioma do aparelho';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionAdd => 'Adicionar';

  @override
  String get actionNext => 'Próximo';

  @override
  String get actionPrevious => 'Voltar';

  @override
  String get actionRetry => 'Tentar de novo';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionLogout => 'Sair';

  @override
  String get commonLoading => 'Carregando…';

  @override
  String get commonError => 'Algo deu errado';

  @override
  String get commonRequired => 'Obrigatório';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get setupTitle => 'Preparação';

  @override
  String get setupTabRooms => 'Hospedagem';

  @override
  String get setupTabGroups => 'Grupos de estudo bíblico';

  @override
  String get appTagline => 'Sistema de inscrição do retiro';

  @override
  String get authSignInGoogle => 'Entrar com o Google';

  @override
  String get authSignInKakao => 'Entrar com o Kakao';

  @override
  String get authSignInDev => 'Login de teste (dev@test.com)';

  @override
  String get authTermsNotice => 'Ao entrar, você aceita os Termos de Serviço.';

  @override
  String authGoogleFailed(String error) {
    return 'Falha ao entrar com o Google: $error';
  }

  @override
  String authKakaoFailed(String error) {
    return 'Falha ao entrar com o Kakao: $error';
  }

  @override
  String authDevFailed(String error) {
    return 'Falha no login de teste: $error';
  }

  @override
  String get profileTitle => 'Configuração do perfil';

  @override
  String get profileSubtitle =>
      'Informe os dados básicos usados na inscrição.\nVocê só precisa fazer isso uma vez.';

  @override
  String get profileNameLabel => 'Nome *';

  @override
  String get profileNameHint => 'Digite seu nome real';

  @override
  String get profileNameRequired => 'Digite seu nome';

  @override
  String get profileAgeLabel => 'Idade *';

  @override
  String get profileAgeHint => 'ex.: 28';

  @override
  String get profileAgeInvalid => 'Digite uma idade válida';

  @override
  String get profileRegionLabel => 'País de residência *';

  @override
  String get profileRegionHint => 'Busque e selecione um país';

  @override
  String get profileRegionRequired => 'Selecione seu país';

  @override
  String get profileSaveStart => 'Salvar e começar';

  @override
  String profileSaveFailed(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get homeLogoutConfirmBody =>
      'Deseja sair?\nVocê pode entrar com outra conta.';

  @override
  String get homeDirectorMode => 'Modo diretor';

  @override
  String get homeManageMenu => 'Gerenciamento';

  @override
  String get homeCreateProgram => 'Criar programa';

  @override
  String get homeCreateProgramSub => 'Gera um UUID e configura um programa';

  @override
  String get homeProgramList => 'Meus programas';

  @override
  String get homeProgramListDirectorSub =>
      'Gerencie os programas que você criou';

  @override
  String get homeProgramListAdminSub =>
      'Gerencie os programas sob sua responsabilidade';

  @override
  String get homeAssignAdmins => 'Designar administradores';

  @override
  String get homeAssignAdminsSub => 'Defina um administrador por programa';

  @override
  String get homeDirectorInfo =>
      'O diretor gerencia todos os programas e pode designar administradores.';

  @override
  String get homeAdminMode => 'Modo administrador';

  @override
  String get homeAdminInfo =>
      'Depois de criar o programa, compartilhe o UUID com os participantes.';

  @override
  String get homeJoinTitle => 'Entrar em um programa';

  @override
  String get homeJoinSub =>
      'Digite o UUID que seu líder enviou para entrar no programa.';

  @override
  String get homeUuidLabel => 'UUID do programa';

  @override
  String get homeJoinButton => 'Entrar';

  @override
  String get homeRecentPrograms => 'Acessados recentemente';

  @override
  String get homeRemoveFromList => 'Remover da lista';

  @override
  String get homeBecomeLeader => 'Você é líder? Mudar para o modo líder';

  @override
  String get homeLeaderCheckTitle => 'Verificação de líder';

  @override
  String homeLeaderCheckBody(String email) {
    return 'O e-mail com que você entrou ($email) está registrado como líder deste capítulo:';
  }

  @override
  String homeLeaderContinent(String value) {
    return 'Continente: $value';
  }

  @override
  String homeLeaderNation(String value) {
    return 'País: $value';
  }

  @override
  String homeLeaderChapter(String value) {
    return 'Capítulo: $value';
  }

  @override
  String get homeLeaderCheckPrompt =>
      'Deseja se registrar como líder de capítulo?';

  @override
  String get homeLeaderDeclineParticipant => 'Não, continuar como participante';

  @override
  String get homeLeaderConfirmRegister => 'Sim, registrar como líder';

  @override
  String get commonSaved => 'Salvo';

  @override
  String commonErrorDetail(String error) {
    return 'Erro: $error';
  }

  @override
  String get sectionDisabled => 'Esta seção está desativada';

  @override
  String get flightSkipTitle => 'Dados de voo dispensados';

  @override
  String flightSkipBody(String dir) {
    return 'Você mora no país anfitrião, então os dados do voo de $dir são dispensados. Se vier de avião, informe abaixo.';
  }

  @override
  String get flightSkipAdd => 'Adicionar dados do voo';

  @override
  String get flightSkipCollapse => 'Dispensar voo';

  @override
  String get regTitle => 'Inscrição';

  @override
  String get regInvalidProgram => 'UUID de programa inválido';

  @override
  String get regScheduleTooltip => 'Programação';

  @override
  String get regSaveDraft => 'Salvar rascunho';

  @override
  String get regReviewSummary => 'Revisar resumo';

  @override
  String get regStepPersonal => 'Dados pessoais';

  @override
  String get regStepArrival => 'Voo de chegada';

  @override
  String get regStepDeparture => 'Voo de volta';

  @override
  String get regStepFood => 'Refeições';

  @override
  String get regStepOptions => 'Passeios / opções';

  @override
  String get regStepRoommate => 'Colega de quarto';

  @override
  String get regStepVolunteer => 'Voluntariado';

  @override
  String get roommateQuestion =>
      'Há alguém com quem você gostaria de dividir o quarto?';

  @override
  String get roommateHelp =>
      'Informe o nome (nome bíblico ou nome real) da pessoa com quem deseja dividir o quarto.\nFaremos o possível para atender.';

  @override
  String get roommateFieldLabel => 'Preferência de colega de quarto (opcional)';

  @override
  String get roommateFieldHint =>
      'ex.: Pedro, João (mesmo quarto)\nou escreva \"Nenhum\"';

  @override
  String get roommateNotice =>
      'A distribuição dos quartos pode ser ajustada a critério do líder.';

  @override
  String get optionsNone => 'Este programa não tem opções especiais';

  @override
  String get optionsSelectPrompt =>
      'Selecione os programas de que vai participar (pode escolher vários)';

  @override
  String get optionsFree => 'Grátis';

  @override
  String get optionsSelectedTotal => 'Total das opções escolhidas';

  @override
  String get genderMale => 'Masculino';

  @override
  String get genderFemale => 'Feminino';

  @override
  String get regContinent => 'Continente *';

  @override
  String get regContinentHint => 'Selecione um continente';

  @override
  String get regNation => 'País *';

  @override
  String get regNationHint => 'Selecione um país';

  @override
  String get regNationDisabled => 'Selecione primeiro um continente';

  @override
  String get regChapter => 'Capítulo *';

  @override
  String get regChapterHint => 'Selecione um capítulo';

  @override
  String get regChapterNoneHint =>
      'Não há capítulos registrados para este país. Digite abaixo.';

  @override
  String get regChapterManualHint => 'Se não estiver na lista, digite abaixo';

  @override
  String get regBranch => 'Nome da sede *';

  @override
  String get regBranchHint => 'ex.: São Paulo, Chicago';

  @override
  String get regRealName => 'Nome real *';

  @override
  String get regBibleName => 'Nome bíblico';

  @override
  String get regBibleNameHint => 'ex.: Pedro, Maria';

  @override
  String get regGender => 'Sexo';

  @override
  String get regAge => 'Idade *';

  @override
  String get foodMedicalTitle => 'Condições de saúde';

  @override
  String get foodMedicalHint =>
      'Informe condições como diabetes, hipertensão, alergias (deixe em branco se não houver)';

  @override
  String get foodRestrictionTitle => 'Alimentos que você não pode comer';

  @override
  String get foodRestrictionHelp => 'Escolha abaixo ou escreva o seu';

  @override
  String get foodRestrictionInputHint =>
      'Escreva os alimentos que você não pode comer';

  @override
  String get foodVegetarian => 'Vegetariano';

  @override
  String get foodVegan => 'Vegano';

  @override
  String get foodHalal => 'Halal';

  @override
  String get foodKosher => 'Kosher';

  @override
  String get foodGluten => 'Intolerância a glúten';

  @override
  String get foodPeanut => 'Alergia a amendoim';

  @override
  String get foodDairy => 'Alergia a laticínios';

  @override
  String get foodSeafood => 'Alergia a frutos do mar';

  @override
  String get foodNone => 'Nenhum';

  @override
  String get foodBreakfastTitle => 'Café da manhã';

  @override
  String get foodSkipBreakfast => 'Normalmente não tomo café da manhã';

  @override
  String get foodSkipBreakfastSub => 'Usado para estimar o número de refeições';

  @override
  String get flightArrival => 'chegada';

  @override
  String get flightDeparture => 'volta';

  @override
  String flightInfoTitle(String dir) {
    return 'Dados do voo de $dir';
  }

  @override
  String flightDateLabel(String dir) {
    return 'Data de $dir *';
  }

  @override
  String flightAirportLabel(String dir) {
    return 'Aeroporto de $dir';
  }

  @override
  String flightTimeLabel(String dir) {
    return 'Horário previsto de $dir';
  }

  @override
  String get flightPickDate => 'Selecione uma data';

  @override
  String get flightNumber => 'Número do voo';

  @override
  String get flightNumberHint => 'ex.: KE123, OZ456';

  @override
  String get flightAutoSearch => 'Buscar voo automaticamente';

  @override
  String get flightNotFound =>
      'Não encontramos os dados do voo. Digite manualmente.';

  @override
  String flightStatus(String value) {
    return 'Situação: $value';
  }

  @override
  String get flightAutoFillHint =>
      'Preenchido automaticamente ao buscar pelo número do voo';

  @override
  String get volQuestion => 'Você pode ajudar na realização do programa?';

  @override
  String get volHelp => 'Marque tudo o que se aplica. (Opcional)';

  @override
  String get volOtherLabel => 'Outras formas de ajudar (opcional)';

  @override
  String get volOtherHint =>
      'Escreva talentos ou recursos que não estejam na lista';

  @override
  String get volPiano => 'Piano';

  @override
  String get volGuitar => 'Violão';

  @override
  String get volBass => 'Baixo';

  @override
  String get volDrums => 'Bateria';

  @override
  String get volViolin => 'Violino';

  @override
  String get volWorshipLead => 'Direção de louvor';

  @override
  String get volVocals => 'Vocal';

  @override
  String get volTranslation => 'Interpretação/Tradução';

  @override
  String get volPhotography => 'Foto/Vídeo';

  @override
  String get volSound => 'Som';

  @override
  String get volDesign => 'Design';

  @override
  String get volIt => 'TI/Tecnologia';

  @override
  String get volChildcare => 'Cuidado de crianças';

  @override
  String get volCooking => 'Cozinha';

  @override
  String get volDriving => 'Motorista';

  @override
  String get volMedical => 'Saúde/Primeiros socorros';

  @override
  String get summaryTitle => 'Resumo da inscrição';

  @override
  String get summarySectionProgram => 'Programa';

  @override
  String get summaryName => 'Nome';

  @override
  String get summaryLocation => 'Local';

  @override
  String get summaryPeriod => 'Datas';

  @override
  String get summaryCountry => 'País';

  @override
  String get summaryBranch => 'Sede';

  @override
  String get summaryRealName => 'Nome real';

  @override
  String get summaryBibleName => 'Nome bíblico';

  @override
  String get summaryAge => 'Idade';

  @override
  String get summaryFlightNo => 'Voo';

  @override
  String get summaryArrAirport => 'Aeroporto de chegada';

  @override
  String get summaryArrTime => 'Chegada prevista';

  @override
  String get summaryDepAirport => 'Aeroporto de saída';

  @override
  String get summaryDepTime => 'Saída prevista';

  @override
  String get summarySectionFood => 'Necessidades alimentares';

  @override
  String get summarySectionOptions => 'Programas escolhidos';

  @override
  String get summarySectionRoommate => 'Preferência de colega de quarto';

  @override
  String get summaryTotalCost => 'Total a pagar';

  @override
  String get summaryNoPaidOptions => 'Nenhuma opção paga selecionada';

  @override
  String get summaryViewImmigration => 'Ver cartão de imigração';

  @override
  String get summarySubmit => 'Enviar';

  @override
  String get summaryEditBtn => 'Editar';

  @override
  String get summarySubmitConfirm =>
      'Deseja enviar sua inscrição?\nDepois do envio, a edição pode ficar restrita.';

  @override
  String get summarySubmitDone => 'Enviado';

  @override
  String get summarySubmitDoneMsg =>
      'Sua inscrição foi enviada com sucesso.\nUm organizador entrará em contato após a análise.';

  @override
  String summarySubmitFailed(String error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get commonNoName => 'Sem nome';

  @override
  String unitPeople(int count) {
    return '$count pessoas';
  }

  @override
  String unitCases(int count) {
    return '$count';
  }

  @override
  String get dashTitle => 'Painel';

  @override
  String get dashExport => 'Exportar';

  @override
  String get dashExportExcel => 'Exportar para Excel';

  @override
  String get dashExportCsv => 'Exportar para CSV';

  @override
  String get dashEditSettings => 'Editar configurações do programa';

  @override
  String get dashSetupSubtitle =>
      'Defina hospedagem e grupos de estudo (etapa antes da distribuição)';

  @override
  String get dashPendingPayments => 'Pagamentos a confirmar';

  @override
  String get dashViewAll => 'Ver tudo';

  @override
  String get dashNoPendingPayments => 'Nenhum pagamento aguardando confirmação';

  @override
  String get dashAttendeeList => 'Participantes';

  @override
  String get dashNoAttendees => 'Ainda não há participantes inscritos';

  @override
  String get dashSendNotice => 'Enviar aviso ao grupo';

  @override
  String get dashNoStats => 'Sem estatísticas';

  @override
  String get dashStatTotal => 'Total de inscritos';

  @override
  String get dashStatSubmitted => 'Concluídos';

  @override
  String get dashStatFoodRestriction => 'Restrições alimentares';

  @override
  String get dashStatPendingPayment => 'Pagamento pendente';

  @override
  String get dashStatArrival => 'Voos de chegada';

  @override
  String get dashStatConfirmedPayment => 'Pagamento confirmado';

  @override
  String get dashPaymentPending => 'Aguardando confirmação';

  @override
  String get dashStatusDone => 'Concluído';

  @override
  String get dashStatusInProgress => 'Em andamento';

  @override
  String get pcTitle => 'Programa criado';

  @override
  String get pcHeading => 'Seu programa foi criado!';

  @override
  String get pcShareUuid => 'Compartilhe o UUID abaixo com os participantes';

  @override
  String get pcCopy => 'Copiar';

  @override
  String get pcCopied => 'UUID copiado';

  @override
  String get pcInfo =>
      'Os participantes podem se inscrever informando este UUID no aplicativo.';

  @override
  String get pcGoDashboard => 'Ir para o painel';

  @override
  String get pcGoHome => 'Início';

  @override
  String get cpProgramType => 'Tipo de programa';

  @override
  String get cpTypeLocal => 'Retiro local';

  @override
  String get cpTypeInternational => 'Retiro internacional';

  @override
  String get cpLocalNote =>
      'Retiro local: as seções de voo e passeio são desativadas automaticamente';

  @override
  String get cpBasicInfo => 'Informações básicas';

  @override
  String get cpNameLabel => 'Nome do programa *';

  @override
  String get cpNameHint => 'ex.: Retiro de Verão 2025';

  @override
  String get cpNameRequired => 'Digite o nome do programa';

  @override
  String get cpLocationLabel => 'Local *';

  @override
  String get cpLocationHint => 'ex.: Centro de Convenções de Jeju';

  @override
  String get cpLocationRequired => 'Digite o local';

  @override
  String get cpStartDate => 'Selecionar data de início';

  @override
  String get cpEndDate => 'Selecionar data de término';

  @override
  String get cpPeriod => 'Selecionar período (início ~ fim)';

  @override
  String get cpHostCountry => 'País anfitrião';

  @override
  String get cpHostCountryHint => 'Busque e selecione um país';

  @override
  String get cpHostCountryHelp =>
      'Participantes que moram no país anfitrião não precisam informar voo';

  @override
  String get cpImmigrationInfo => 'Informações de imigração';

  @override
  String get cpImmigrationDesc =>
      'Informações que os participantes podem mostrar ao agente de imigração na chegada (opcional)';

  @override
  String get cpNearestAirport => 'Aeroporto mais próximo';

  @override
  String get cpAirportHint => 'ex.: Aeroporto Intl. de Incheon (ICN)';

  @override
  String get cpContacts => 'Contatos no local (2)';

  @override
  String get cpName1 => 'Nome 1';

  @override
  String get cpName1Hint => 'João Silva';

  @override
  String get cpPhone1 => 'Telefone 1';

  @override
  String get cpName2 => 'Nome 2';

  @override
  String get cpName2Hint => 'Maria Souza';

  @override
  String get cpPhone2 => 'Telefone 2';

  @override
  String get cpSectionsTitle => 'Ativar seções da inscrição';

  @override
  String get cpSectionsDesc => 'Escolha quais itens os participantes verão';

  @override
  String get cpSecVolunteer =>
      'Recursos de apoio ao programa (instrumentos, tradução etc.)';

  @override
  String get cpSpecialOptions => 'Programas especiais / opções de passeio';

  @override
  String get cpOptionsDesc =>
      'Defina um custo por opção para que os participantes possam escolher';

  @override
  String cpOptionCost(String value) {
    return 'Custo: $value';
  }

  @override
  String get cpOptionName => 'Nome da opção';

  @override
  String get cpOptionNameHint => 'Passeio Jeju Roteiro A';

  @override
  String get cpOptionCostLabel => 'Custo';

  @override
  String get cpCreateButton => 'Criar programa (gerar UUID)';

  @override
  String get cpDupTitle => 'O programa já existe';

  @override
  String get cpDupBody =>
      'Já existe um programa com o mesmo nome e data de início.\nIr para a tela de UUID do programa existente?';

  @override
  String get cpDupGoExisting => 'Ir para o programa existente';

  @override
  String cpCreateFailed(String error) {
    return 'Falha ao criar o programa: $error';
  }

  @override
  String get epSaved => 'Configurações salvas';

  @override
  String get epNotFound => 'Programa não encontrado';

  @override
  String get epTourLocked =>
      'O retiro já começou, então as opções de passeio não podem ser editadas';

  @override
  String epOptionContact(String value) {
    return 'Responsável: $value';
  }

  @override
  String get epAddOption => 'Adicionar opção';

  @override
  String get epEditOption => 'Editar opção';

  @override
  String get epSaveChanges => 'Salvar alterações';

  @override
  String get epOptionNameReq => 'Nome da opção *';

  @override
  String get epOptionCostNum => 'Custo (número)';

  @override
  String get epOptionContactName => 'Nome do responsável';

  @override
  String get epOptionDesc => 'Descrição (opcional)';

  @override
  String get epPickDate => 'Selecionar data';

  @override
  String epPhotos(int count) {
    return 'Fotos ($count/6)';
  }

  @override
  String get epPhotoUrlTitle => 'Adicionar URL da foto';

  @override
  String get epPhotoUrlLabel => 'URL da imagem';

  @override
  String get epCapacity => 'Vagas';

  @override
  String get epSignupDeadline => 'Prazo de inscrição';

  @override
  String get epBrochureUrl => 'Link do folheto';

  @override
  String get epVideoUrl => 'Link do vídeo de apresentação';

  @override
  String get tourCapacityLabel => 'Vagas restantes';

  @override
  String tourRemaining(int remaining, int capacity) {
    return '$remaining / $capacity';
  }

  @override
  String get tourFull => 'Esgotado';

  @override
  String get tourClosed => 'Encerrado';

  @override
  String tourDeadline(String date) {
    return 'Prazo: $date';
  }

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get blTitle => 'Registrar-se como líder';

  @override
  String get blInfo =>
      'Registrar-se como líder permite criar programas de retiro e gerenciar participantes.';

  @override
  String get blLoginAccount => 'Conta conectada';

  @override
  String get blLeaderName => 'Nome do líder *';

  @override
  String get blLeaderNameHint => 'Nome que os participantes verão';

  @override
  String get blRegisterButton => 'Registrar e criar um evento';

  @override
  String blLeaderRegFailed(String error) {
    return 'Falha ao registrar o líder: $error';
  }

  @override
  String get sosTitle => 'SOS de emergência';

  @override
  String get sosHealth => '🚑 Emergência médica/de saúde';

  @override
  String get sosSafety => '🆘 Ameaça à segurança pessoal';

  @override
  String get sosLost => '🗺️ Estou perdido';

  @override
  String get sosGpsOff => 'O GPS está desligado. Ative-o nas configurações.';

  @override
  String get sosPermDenied =>
      'Permissão de localização negada. Enviando SOS sem localização.';

  @override
  String sosLocationError(String error) {
    return 'Não foi possível obter a localização: $error';
  }

  @override
  String get sosSentTitle => 'SOS enviado';

  @override
  String get sosSentMsg =>
      'Um alerta de emergência foi enviado aos organizadores.\nAguarde um momento.';

  @override
  String sosSendFailed(String error) {
    return 'Falha ao enviar: $error';
  }

  @override
  String get sosBanner =>
      'Um alerta é enviado aos organizadores imediatamente.\nUse somente em emergência.';

  @override
  String get sosSelectType => 'Selecione o tipo de situação';

  @override
  String get sosMessageLabel => 'Mensagem adicional (opcional)';

  @override
  String get sosMessageHint => 'Descreva brevemente sua situação';

  @override
  String sosGpsConfirmed(String value) {
    return 'Localização GPS confirmada $value';
  }

  @override
  String get sosGpsChecking => 'Verificando a localização GPS...';

  @override
  String get sosSending => 'Enviando...';

  @override
  String get sosSend => 'Enviar SOS';

  @override
  String get sosFabConfirm =>
      'Enviar um alerta de emergência aos organizadores?';

  @override
  String schLoadFailed(String error) {
    return 'Falha ao carregar a programação: $error';
  }

  @override
  String get schAddTitle => 'Adicionar evento';

  @override
  String get schTitleLabel => 'Título *';

  @override
  String get schTitleHint => 'Culto de abertura';

  @override
  String get schDescLabel => 'Descrição (opcional)';

  @override
  String get schPickTime => 'Selecionar horário';

  @override
  String get schTimezone => 'Fuso horário';

  @override
  String get schTzAuto => 'Definido automaticamente pelo fuso do seu aparelho';

  @override
  String get schTzReset => 'Voltar ao fuso do aparelho';

  @override
  String get schAllRequired => 'Informe título, data e horário';

  @override
  String schAddFailed(String error) {
    return 'Falha ao adicionar: $error';
  }

  @override
  String get schTzChangeTitle => 'Alterar fuso horário';

  @override
  String get schTzUseDevice => 'Usar o fuso do meu aparelho';

  @override
  String get schTzExamples =>
      'ex.: Asia/Seoul, America/Sao_Paulo, Europe/London';

  @override
  String schTzChangeFailed(String error) {
    return 'Falha ao alterar o fuso horário: $error';
  }

  @override
  String get schDeleteTitle => 'Excluir evento';

  @override
  String get schDeleteConfirm => 'Excluir este evento?';

  @override
  String schDeleteFailed(String error) {
    return 'Falha ao excluir: $error';
  }

  @override
  String get schEmpty => 'Nenhum evento programado';

  @override
  String get immTitle => 'Cartão de imigração';

  @override
  String get immFullscreenTooltip => 'Tela cheia (mostrar ao agente)';

  @override
  String get immNotFound => 'Informações do programa não encontradas.';

  @override
  String get immBanner =>
      'Toque no botão de tela cheia no canto superior direito para mostrar ao agente.';

  @override
  String get immCardPurpose => 'PURPOSE OF VISIT / Motivo da viagem';

  @override
  String get immCardConference =>
      'Religious Conference / Conferência religiosa';

  @override
  String get immCardVenue => 'VENUE / Local';

  @override
  String get immCardDate => 'DATE / Data';

  @override
  String get immCardAirport => 'NEAREST AIRPORT / Aeroporto mais próximo';

  @override
  String get immCardContact => 'ON-SITE CONTACT / Contato no local';

  @override
  String get immCardFooter =>
      'I am attending the above religious conference as a participant.\nParticipo da conferência religiosa acima como participante.';

  @override
  String get immExitHint =>
      'Tap anywhere to exit fullscreen\nToque em qualquer lugar para sair da tela cheia';

  @override
  String setupRoomsMade(int count) {
    return 'Quartos criados · $count';
  }

  @override
  String get setupRoomsEmpty =>
      'Ainda não há quartos.\nUse o botão no canto inferior direito para criá-los em lote.';

  @override
  String get setupBulkAddRooms => 'Criar quartos em lote';

  @override
  String setupRoomsAdded(int count) {
    return '$count quartos criados';
  }

  @override
  String get setupReconcileTitle => 'Inscritos x capacidade';

  @override
  String get setupMale => 'Homens';

  @override
  String get setupFemale => 'Mulheres';

  @override
  String setupMixedSeats(int count) {
    return 'Quartos de casal/família: $count vagas (distribuídas por família)';
  }

  @override
  String setupRegVsSeats(int regs, int seats) {
    return 'Inscritos $regs · Capacidade $seats';
  }

  @override
  String setupSeatShortage(int count) {
    return 'Faltam $count vagas';
  }

  @override
  String setupRoomCapacity(int count) {
    return '$count pessoas';
  }

  @override
  String get setupCouple => 'Quarto de casal';

  @override
  String get setupCoupleSub => '2 pessoas · misto';

  @override
  String get setupFamily => 'Quarto de família';

  @override
  String get setupFamilySub => '3–4 pessoas · misto';

  @override
  String get setupDorm => 'Quarto coletivo';

  @override
  String get setupDormSub => '5+ · um só sexo';

  @override
  String get setupMixed => 'Família (misto)';

  @override
  String get setupRoomType => 'Tipo de quarto';

  @override
  String get setupNameRule => 'Padrão de nome';

  @override
  String get setupNameRuleHint => 'ex.: 3A 3##';

  @override
  String get setupStartNum => 'Início nº';

  @override
  String get setupCount => 'Quantidade';

  @override
  String get setupCapacity => 'Capacidade';

  @override
  String get setupFloor => 'Andar (opcional)';

  @override
  String get setupMixedNotAllowed => 'Misto não permitido';

  @override
  String get setupFamilyAuto => 'Unidade familiar (mista) — automático';

  @override
  String get setupBulkValidation =>
      'Confira o padrão de nome, a quantidade e a capacidade';

  @override
  String setupGroupsMade(int count) {
    return 'Grupos criados · $count';
  }

  @override
  String get setupGroupsEmpty =>
      'Ainda não há grupos.\nUse o botão no canto inferior direito para criá-los.';

  @override
  String get setupMakeGroups => 'Criar grupos';

  @override
  String get setupMakeGroupsPrompt =>
      'Quantos grupos? (Grupo 1, Grupo 2 … criados automaticamente)';

  @override
  String get setupGroupCount => 'Número de grupos';

  @override
  String get setupGroupCountSuffix => '';

  @override
  String get setupMake => 'Criar';

  @override
  String setupGroupsCreated(int count) {
    return '$count grupos criados';
  }

  @override
  String get setupMakeGroupsFirst => 'Crie os grupos primeiro';

  @override
  String setupEvenPerGroup(int count) {
    return 'Cerca de $count por grupo, equilibrado';
  }

  @override
  String setupUnevenPerGroup(int remCount, int bigger, int base) {
    return '$remCount grupos ficam com $bigger, os demais com $base';
  }

  @override
  String get setupGroupSummary => 'Resumo dos grupos';

  @override
  String setupRegAndGroups(int total, int groups) {
    return '$total inscritos · $groups grupos';
  }

  @override
  String setupBalancePreview(String preview) {
    return 'Com equilíbrio de idade/sexo — $preview';
  }

  @override
  String setupLeaderless(int count) {
    return '$count sem líder';
  }

  @override
  String get setupNoPassageLocation => 'Sem passagem/local';

  @override
  String get setupNoLeader => 'Sem líder';

  @override
  String get setupEditGroupMenu => 'Editar líder/passagem/local';

  @override
  String setupEditGroupTitle(String name) {
    return 'Editar $name';
  }

  @override
  String get setupGroupName => 'Nome do grupo';

  @override
  String get setupLeaderName => 'Nome do líder (pastor)';

  @override
  String get setupLeaderPhone => 'Telefone do líder';

  @override
  String get setupPassage => 'Passagem (ex.: João 10)';

  @override
  String get setupLocation => 'Local do encontro';

  @override
  String get expColNo => 'N.º';

  @override
  String get expArrFlight => 'Voo de chegada';

  @override
  String get expArrTime => 'Data/hora de chegada';

  @override
  String get expDepFlight => 'Voo de volta';

  @override
  String get expDepTime => 'Data/hora de saída';

  @override
  String get expOptions => 'Opções escolhidas';

  @override
  String get expTotalCost => 'Custo total';

  @override
  String get expPaymentStatus => 'Situação do pagamento';

  @override
  String get expSubmittedCol => 'Inscrição concluída';

  @override
  String get expUnregistered => 'Não inscrito';

  @override
  String get expIncomplete => 'Incompleto';

  @override
  String get expRoster => 'Lista de participantes';

  @override
  String get regStepCompanion => 'Acompanhantes';

  @override
  String get regStepBuddy => 'Pedidos de companhia';

  @override
  String get buddyTitle => 'Pessoas com quem você quer ficar';

  @override
  String get buddyDesc =>
      'Ao escolher alguém, um pedido é enviado. Só vale quando a pessoa aceita.';

  @override
  String get buddyRoommateSection => 'Pedidos de colega de quarto';

  @override
  String get buddyGroupSection => 'Pedidos de grupo de estudo';

  @override
  String get buddySearchHint => 'Busque por nome ou nome bíblico…';

  @override
  String get buddySendRoommate => 'Pedir como colega de quarto';

  @override
  String get buddySendGroup => 'Pedir o mesmo grupo';

  @override
  String get buddySentSection => 'Pedidos que você enviou';

  @override
  String get buddyReceivedSection => 'Pedidos que você recebeu';

  @override
  String get buddyStatusPending => 'Pendente';

  @override
  String get buddyStatusAccepted => 'Aceito';

  @override
  String get buddyStatusDeclined => 'Recusado';

  @override
  String get buddyAccept => 'Aceitar';

  @override
  String get buddyDecline => 'Recusar';

  @override
  String get buddyKindRoommate => 'Colega de quarto';

  @override
  String get buddyKindGroup => 'Grupo';

  @override
  String get buddyReqSent => 'Pedido enviado';

  @override
  String get buddyRoommateSameGenderNote =>
      'Pedidos de colega de quarto só podem ser enviados a pessoas do mesmo sexo ou à família que viaja com você.';

  @override
  String get buddyReceivedEmpty => 'Nenhum pedido recebido';

  @override
  String get buddyNoCandidates =>
      'Ainda não há outros participantes para escolher';

  @override
  String buddyRequestLine(String kind) {
    return 'Pedido de $kind';
  }

  @override
  String get companionTitle => 'Acompanhantes (casal/família)';

  @override
  String get companionDesc =>
      'Se vier com cônjuge ou família, adicione aqui. Cada um conta para o número de vagas e para o transporte.';

  @override
  String get companionAdd => 'Adicionar acompanhante';

  @override
  String get companionEmpty => 'Deixe vazio se você vem sozinho.';

  @override
  String get companionLanguage => 'Idioma';

  @override
  String get companionSameFlight => 'Mesmo voo que o meu';

  @override
  String get companionArrivalFlightNo => 'Voo de chegada do acompanhante';

  @override
  String get companionDepartureFlightNo => 'Voo de volta do acompanhante';

  @override
  String get companionNeedsPickup => 'Precisa de transporte';

  @override
  String companionCount(int count) {
    return '$count acompanhante(s)';
  }

  @override
  String get companionAddTitle => 'Adicionar acompanhante';

  @override
  String get companionEditTitle => 'Editar acompanhante';

  @override
  String get asnTitle => 'Distribuição';

  @override
  String get asnAutoAssign => 'Distribuir automaticamente';

  @override
  String asnAutoRoomsDone(int count) {
    return 'Quartos distribuídos — $count alocados';
  }

  @override
  String asnAutoGroupsDone(int count) {
    return 'Grupos distribuídos — $count alocados';
  }

  @override
  String asnUnplaced(int count) {
    return '$count não puderam ser alocados';
  }

  @override
  String get asnUnassigned => 'Sem distribuição';

  @override
  String asnUnassignedCount(int count) {
    return '$count sem distribuição';
  }

  @override
  String get asnPickRoom => 'Escolher quarto';

  @override
  String get asnPickGroup => 'Escolher grupo';

  @override
  String get asnNoRooms => 'Crie os quartos em Preparação primeiro';

  @override
  String get asnNoGroups => 'Crie os grupos em Preparação primeiro';

  @override
  String get asnAllAssigned => 'Todos foram distribuídos';

  @override
  String get dashAssignSubtitle =>
      'Distribua quartos e grupos de estudo bíblico';

  @override
  String get dashDispatchSubtitle =>
      'Lista de motoristas e distribuição automática das vans';

  @override
  String get dspTitle => 'Transporte';

  @override
  String get dspTabArrival => 'Busca na chegada';

  @override
  String get dspTabDeparture => 'Leva na volta';

  @override
  String get dspAddVan => 'Adicionar van';

  @override
  String get dspAutoDispatch => 'Distribuir automaticamente';

  @override
  String get dspNoRuns => 'Cadastre primeiro uma van (motorista e capacidade)';

  @override
  String dspAutoDone(int assigned, int unassigned) {
    return '$assigned alocados · $unassigned sem van';
  }

  @override
  String dspUnassignedCount(int count) {
    return 'Sem van $count';
  }

  @override
  String get dspAllAssigned => 'Todos alocados';

  @override
  String get dspPickVan => 'Escolher van';

  @override
  String get dspDriverUnset => 'Sem motorista';

  @override
  String get dspNewVan => 'Nova van';

  @override
  String get dspEditVan => 'Editar van';

  @override
  String get dspAirport => 'Aeroporto';

  @override
  String get dspVehicle => 'Veículo';

  @override
  String get dspDriverName => 'Nome do motorista';

  @override
  String get dspDriverPhone => 'Telefone do motorista';

  @override
  String get dspCapacityLabel => 'Capacidade';

  @override
  String get dspMeetPoint => 'Ponto de encontro';

  @override
  String get dspDeleteVan => 'Excluir van';

  @override
  String get mtrTitle => 'Meu transporte';

  @override
  String get mtrArrival => 'Busca na chegada';

  @override
  String get mtrDeparture => 'Leva na volta';

  @override
  String mtrArrivalRoute(String airport) {
    return '$airport → Local do retiro';
  }

  @override
  String mtrDepartureRoute(String airport) {
    return 'Local do retiro → $airport';
  }

  @override
  String get mtrPending => 'O transporte será organizado em breve';

  @override
  String get mtrAssigned => 'Alocado';

  @override
  String get mtrPendingBadge => 'Pendente';

  @override
  String get mtrVehicle => 'Veículo';

  @override
  String get mtrDriver => 'Motorista';

  @override
  String get mtrCoPassengers => 'Com';

  @override
  String get mtrMeetPoint => 'Ponto de encontro';

  @override
  String get mtrSelfDrive => 'Vou por conta própria';

  @override
  String get mtrSelfDriveDesc => 'Desative se não precisar de transporte';

  @override
  String get mtrHostCountryTitle =>
      'Você não entra na lista de transporte do aeroporto';

  @override
  String get mtrHostCountryDesc =>
      'Você participa desde o país anfitrião, então não está na lista de transporte do aeroporto. Vem de avião? Informe seu voo na inscrição e você será incluído.';

  @override
  String get rdyTitle => 'Situação da preparação';

  @override
  String get rdySubtitle => 'O que está travado e com quem falar';

  @override
  String get rdySectionItems => 'Itens de preparação';

  @override
  String get rdySectionCohorts => 'Participantes do país e do exterior';

  @override
  String get rdySectionBlocked => 'Pessoas para contatar';

  @override
  String get rdyLodging => 'Hospedagem';

  @override
  String get rdyTransport => 'Vans de transporte';

  @override
  String get rdyFlights => 'Voos não informados';

  @override
  String get rdyMeals => 'Refeições';

  @override
  String get rdyPayment => 'Taxas';

  @override
  String get rdyRoles => 'Cargos na igreja';

  @override
  String get rdyDomestic => 'Do país anfitrião';

  @override
  String get rdyOverseas => 'Do exterior';

  @override
  String get rdySkipped => 'Dispensado';

  @override
  String get rdyUnspecified => 'Não informado';

  @override
  String get rdyStuckPersonal => 'Dados pessoais';

  @override
  String get rdyStuckMeals => 'Refeições';

  @override
  String get rdyStuckFlight => 'Voo';

  @override
  String get rdyStuckLodging => 'Hospedagem';

  @override
  String get rdyStuckPayment => 'Taxas';

  @override
  String get rdyStatusOk => 'Em dia';

  @override
  String get rdyStatusWarn => 'Atenção';

  @override
  String get rdyStatusStop => 'Insuficiente';

  @override
  String get rdyStatusIdle => 'Não configurado';

  @override
  String get rdyNoBlocked => 'Está todo mundo em dia';

  @override
  String get rdyRolesUnreliable => 'Mais da metade está sem cargo registrado';

  @override
  String get rdyOpenCard => 'Ver situação da preparação';

  @override
  String get rdyOpenCardSub =>
      'O que está travado e com quem falar, de relance';

  @override
  String get privacyTitle => 'Como usamos seus dados';

  @override
  String get privacySummary =>
      'O que você informa aqui é usado apenas para organizar o retiro.';

  @override
  String get privacyWhatTitle => 'O que coletamos';

  @override
  String get privacyWhat =>
      'Nome, nome bíblico, sexo, idade, país de residência e sede; dados do voo; restrições alimentares; condições de saúde; preferência de colega de quarto; situação do pagamento. Se você usar o SOS, sua localização naquele momento também é enviada.';

  @override
  String get privacyWhyTitle => 'Para quê';

  @override
  String get privacyWhy =>
      'Para distribuir quartos e grupos, organizar o transporte do aeroporto, preparar as refeições e atender emergências. Nada além disso.';

  @override
  String get privacyWhoTitle => 'Quem pode ver';

  @override
  String get privacyWho =>
      'Os organizadores do retiro. Os outros participantes veem apenas o que você compartilha pelo QR — seu versículo, seus motivos de oração e os contatos que você ativar. As informações de saúde nunca são compartilhadas com participantes; não aparecem nas listas, um organizador as abre por pessoa quando é necessário, e esse acesso fica registrado.';

  @override
  String get privacyWhereTitle => 'Onde ficam guardados';

  @override
  String get privacyWhere =>
      'Os dados ficam em um banco de dados na nuvem localizado nos Estados Unidos. Isso significa que eles saem do seu país de residência.';

  @override
  String get privacyKeepTitle => 'Por quanto tempo';

  @override
  String get privacyKeep =>
      'Guardados por até um ano após o fim do retiro e depois excluídos.';

  @override
  String get privacyRightsTitle => 'Suas opções';

  @override
  String get privacyRights =>
      'Você pode alterar o que informou a qualquer momento. No compartilhamento por QR, você pode desativar cada item, cortar quem salvou seu cartão ou criar um QR novo para que os códigos antigos parem de funcionar. Para excluir seus dados, peça a um organizador.';

  @override
  String get privacyAgree => 'Li estas informações';

  @override
  String get privacyMore => 'Ver mais';

  @override
  String get privacyLess => 'Ver menos';

  @override
  String get regStepFee => 'Taxa';

  @override
  String get feePrompt => 'Escolha um nível de taxa.';

  @override
  String get feeTierBasic => 'Padrão';

  @override
  String get feeTierPremium => 'Premium';

  @override
  String get feeNotSet => 'A taxa ainda não foi definida.';

  @override
  String get discountTitle => 'Pedido de desconto';

  @override
  String get discountPrompt =>
      'Se alguma destas situações for a sua, escolha-a.';

  @override
  String get discountNone => 'Sem pedido de desconto';

  @override
  String get discountReasonLabel => 'Observação (opcional)';

  @override
  String get discountReasonHint => 'Algo que os organizadores precisem saber';

  @override
  String get discountStatusPending => 'Aguardando a análise dos organizadores.';

  @override
  String discountStatusApproved(String amount) {
    return 'Aprovado — $amount de desconto';
  }

  @override
  String get discountStatusRejected => 'Não aprovado.';

  @override
  String discountAdminNote(String note) {
    return 'Observação do organizador: $note';
  }

  @override
  String get cohortSection => 'Equipes de estudo bíblico';

  @override
  String get cohortHint =>
      'As equipes são divididas primeiro por idioma e depois por idade. Adulto 20+ · Junior até 19.';

  @override
  String get cohortMinSize => 'Tamanho mínimo da equipe';

  @override
  String get cohortKeep => 'Deixar como está';

  @override
  String get cohortKeepSub =>
      'Se nenhuma equipe servir, ficam sem equipe para você decidir';

  @override
  String get cohortAbsorb => 'Passar para a equipe Adulto do mesmo idioma';

  @override
  String get cohortAbsorbSub => 'Dá prioridade ao idioma que eles compartilham';

  @override
  String get cohortMerge => 'Juntar com a mesma faixa etária de outro idioma';

  @override
  String get cohortMergeSub => 'Dá prioridade a ficar com gente da mesma idade';

  @override
  String get studyLangTitle => 'Em que idioma você quer estudar a Bíblia?';

  @override
  String get studyLangBody =>
      'As equipes de estudo bíblico são formadas por este idioma.';

  @override
  String get studyLangNote => 'Você pode mudar isso depois, na sua inscrição.';

  @override
  String get regStepStudyLang => 'Estudo bíblico';

  @override
  String get discountNoOptions =>
      'Este retiro não oferece pedidos de desconto.';

  @override
  String discountDomesticOnly(String country) {
    return 'Só podem pedir desconto os participantes que vêm de $country.';
  }

  @override
  String get cpFeeSection => 'Taxa';

  @override
  String get cpFeeBasic => 'Taxa padrão';

  @override
  String get cpFeePremium => 'Taxa premium';

  @override
  String get cpFeeBasicDesc => 'O que a taxa padrão inclui';

  @override
  String get cpFeePremiumDesc => 'O que a taxa premium inclui';

  @override
  String get cpFeeHint => 'Deixe vazio se você não oferece esse nível.';

  @override
  String get cpFeeInvalid => 'Digite um número igual ou maior que 0.';

  @override
  String get cpDiscountSection => 'Opções de desconto';

  @override
  String get cpDiscountHint =>
      'Motivos que os participantes podem escolher ao pedir desconto — por exemplo, \"Participo só um dia\".';

  @override
  String get cpDiscountLabel => 'Texto que os participantes verão';

  @override
  String get cpDiscountAmount => 'Valor do desconto (opcional)';

  @override
  String get cpDiscountAmountHint => 'Deixe vazio para decidir caso a caso.';

  @override
  String get cpDiscountAdd => 'Adicionar opção de desconto';

  @override
  String get cpDiscountRemove => 'Remover';

  @override
  String get cpDiscountEmpty => 'Ainda não há opções de desconto.';

  @override
  String get adDiscountTitle => 'Pedidos de desconto';

  @override
  String get adDiscountNone => 'Nenhum pedido de desconto.';

  @override
  String get adDiscountApprove => 'Aprovar';

  @override
  String get adDiscountReject => 'Recusar';

  @override
  String get adDiscountAmount => 'Valor do desconto';

  @override
  String get adDiscountNote => 'Observação (opcional)';

  @override
  String get adDiscountAmountReq => 'É preciso informar um valor para aprovar.';

  @override
  String get adDiscountSaved => 'Salvo.';

  @override
  String get adDiscountPending => 'Pendente';

  @override
  String get adDiscountApproved => 'Aprovado';

  @override
  String get adDiscountRejected => 'Recusado';

  @override
  String get myProgramsTitle => 'Meus retiros';

  @override
  String get myProgramsEmpty =>
      'Você ainda não criou nenhum retiro.\nUse o botão abaixo para criar um.';

  @override
  String get myProgramsEdit => 'Editar';

  @override
  String myProgramsRegistered(int count) {
    return '$count inscritos';
  }

  @override
  String get cpCurrency => 'Moeda';

  @override
  String get cpCurrencyHint =>
      'Todos os participantes deste retiro veem os valores nesta moeda. Não há conversão de câmbio.';

  @override
  String cpCurrencyFixed(String code) {
    return 'Retiros internacionais são cobrados em $code. Os participantes vêm de vários países, então a moeda é a mesma para todos.';
  }

  @override
  String get flightNotBookedYet => 'Ainda não comprei minha passagem';

  @override
  String get flightNotBookedYetHint =>
      'Informe apenas a data prevista. Você pode acrescentar o voo depois.';

  @override
  String get flightEstimatedNotice =>
      'Isto fica registrado como previsão, não como voo confirmado. Volte e informe o voo assim que comprar.';

  @override
  String get expFlightEstimated => '(previsão — sem passagem)';

  @override
  String get buddyFamilyTitle => 'Vocês viajam juntos?';

  @override
  String get buddyFamilyBody =>
      'Esta pessoa é de outro sexo. Por padrão os quartos são do mesmo sexo; só podem dividir se forem família viajando junta (cônjuge, pai e filho e assim por diante). A pessoa também precisa aceitar.';

  @override
  String get buddyFamilyConfirm => 'Sim, somos família';

  @override
  String get myProgramsDelete => 'Excluir';

  @override
  String get myProgramsDeleteTitle => 'Excluir este retiro?';

  @override
  String myProgramsDeleteBody(String name) {
    return '\"$name\" deixará de aparecer para todos. As inscrições e distribuições são mantidas — peça a um administrador se precisar recuperá-lo.';
  }

  @override
  String myProgramsDeleteHasRegistrations(int count) {
    return '$count pessoas já se inscreveram. Digite o nome do retiro para confirmar.';
  }

  @override
  String get myProgramsDeleteTypeName => 'Nome do retiro';

  @override
  String get myProgramsDeleted => 'Excluído.';

  @override
  String get mealsTitle => 'Restrições alimentares';

  @override
  String get mealsSubtitle => 'Quem não pode comer o quê — para a cozinha';

  @override
  String get mealsEmpty => 'Ninguém informou restrição alimentar.';

  @override
  String get mealsRestriction => 'Não pode comer · observações';

  @override
  String get mealsSkipsBreakfast => 'não toma café da manhã';

  @override
  String mealsSummary(int restricted, int total) {
    return '$restricted de $total participantes';
  }

  @override
  String mealsPdfSummary(int restricted, int total) {
    return '$restricted de $total participantes inscritos informaram restrição alimentar.';
  }

  @override
  String get mealsPdfNote =>
      'Compilado a partir do que cada participante escreveu. Confirme com a pessoa antes de supor que uma alergia é leve.';

  @override
  String get mealsDownloadPdf => 'Baixar PDF';

  @override
  String get mealsHint => 'Toque duas vezes para ver quem não pode comer o quê';

  @override
  String get mealsNotSubmitted => 'não enviado';

  @override
  String mealsDownloadFailed(String detail) {
    return 'Não foi possível salvar o PDF: $detail';
  }

  @override
  String get regStepHotel => 'Hotel';

  @override
  String get hotelTitle => 'Você fica antes ou depois?';

  @override
  String get hotelBody =>
      'Se chegar antes ou ficar depois do passeio, você vai precisar de hotel. Escolha o nível e quantas noites.';

  @override
  String get hotelNoOptions =>
      'Os organizadores ainda não definiram os níveis de hotel. Você pode voltar aqui mais tarde.';

  @override
  String get hotelNone => 'Não preciso de hotel';

  @override
  String hotelPerNight(String amount) {
    return '$amount / noite';
  }

  @override
  String get hotelPriceTbd => 'A definir';

  @override
  String get hotelNightsBefore => 'Noites antes do retiro';

  @override
  String get hotelNightsAfter => 'Noites depois do passeio';

  @override
  String hotelNightsCount(int count) {
    return '$count';
  }

  @override
  String get hotelEstimate => 'Custo estimado do hotel';

  @override
  String get hotelNotInFee =>
      'Não está incluído na taxa do retiro. O pagamento é feito à parte.';

  @override
  String get hotelSectionTitle => 'Níveis de hotel (antes / depois)';

  @override
  String get hotelSectionHelp =>
      'Só os participantes que vêm do exterior veem isto. Eles escolhem o nível e a quantidade de noites.';

  @override
  String get hotelLevelKo => 'Nível (coreano)';

  @override
  String get hotelLevelEn => 'Nível (inglês)';

  @override
  String get hotelLevelEs => 'Nível (espanhol)';

  @override
  String get hotelPricePerNightLabel => 'Preço por noite';

  @override
  String get hotelAddLevel => 'Adicionar nível';

  @override
  String get hotelNoLevelsYet => 'Nenhum nível adicionado ainda';

  @override
  String get summarySectionHotel => 'Hotel antes / depois';

  @override
  String summaryHotelNights(int before, int after) {
    return '$before antes · $after depois';
  }

  @override
  String hotelComputed(int before, int after) {
    return 'Você precisa de $before noite(s) antes do retiro e $after noite(s) depois.';
  }

  @override
  String hotelComputedBeforeOnly(int before) {
    return 'Você precisa de $before noite(s) antes do retiro. Não deu para calcular as noites depois — falta o voo de volta.';
  }

  @override
  String hotelComputedAfterOnly(int after) {
    return 'Você precisa de $after noite(s) depois. Não deu para calcular as noites antes — falta o voo de chegada.';
  }

  @override
  String get hotelComputedNone =>
      'Seus voos chegam e saem dentro do período do retiro, então você não precisa de hotel.';

  @override
  String get hotelNoFlightYet =>
      'Informe seus voos e calcularemos de quantas noites você precisa. Você também pode definir abaixo.';

  @override
  String get hotelPickPrompt => 'Escolha a opção que você prefere:';

  @override
  String get hotelAdjustHint =>
      'Calculado com seus voos e as datas do retiro. Corrija abaixo se não bater.';

  @override
  String get hotelRecalc => 'Recalcular pelos meus voos';

  @override
  String get pcInviteLink => 'Link de convite';

  @override
  String get pcInviteLinkHelp =>
      'Envie isto no lugar do UUID. Ao abrir, a pessoa entra direto neste retiro — sem digitar código nenhum.';

  @override
  String get pcCopyLink => 'Copiar link';

  @override
  String get pcLinkCopied => 'Link de convite copiado';

  @override
  String get tgSectionTitle => 'Avisos pelo Telegram';

  @override
  String get tgSectionHelp =>
      'As novas inscrições e alterações deste retiro são enviadas para o seu Telegram. Deixe vazio para usar o bot padrão.';

  @override
  String get tgBotToken => 'Token do bot';

  @override
  String get tgBotTokenHint => '123456789:AA…  (do @BotFather)';

  @override
  String get tgChatId => 'ID do chat';

  @override
  String get tgChatIdHint => 'ex.: -1001234567890 (grupo) ou seu ID de usuário';

  @override
  String get tgConfigured => 'Este retiro já tem um bot configurado';

  @override
  String get tgTokenHidden =>
      'O token salvo não é mostrado de novo. Deixe vazio para mantê-lo; digite um novo para substituir.';

  @override
  String get tgClearToken => 'Remover o bot';

  @override
  String get tgInvalidToken =>
      'Isso não parece um token de bot (ex.: 123456789:AA…)';

  @override
  String get tgHowTo =>
      'No Telegram, fale com o @BotFather → /newbot → copie o token. Adicione o bot ao seu grupo e use o ID desse grupo.';

  @override
  String get hotelLevelPt => 'Nível (português)';

  @override
  String get libTitle => 'Biblioteca';

  @override
  String get libSubtitle =>
      'Materiais compartilhados no retiro — abra quando quiser';

  @override
  String get libEmpty => 'Ainda não há materiais.';

  @override
  String get libEmptyAdmin =>
      'Ainda não há materiais. Use o botão abaixo para adicionar um PDF.';

  @override
  String get libOpen => 'Abrir';

  @override
  String get libAdd => 'Adicionar material';

  @override
  String get libPickPdf => 'Escolher um PDF';

  @override
  String get libPickOnWeb =>
      'Os PDFs são adicionados pelo navegador de um computador. Acesse ubf.coolsistema.com e entre por lá.';

  @override
  String get libItemTitle => 'Título';

  @override
  String get libItemTitleHint => 'ex.: Lição 1 — João 10';

  @override
  String get libItemDesc => 'Observação (opcional)';

  @override
  String get libPublished => 'Visível para os participantes';

  @override
  String get libHidden => 'Oculto';

  @override
  String get libUploading => 'Enviando…';

  @override
  String libUploadFailed(String detail) {
    return 'Não foi possível enviar: $detail';
  }

  @override
  String get libDeleteTitle => 'Excluir este material?';

  @override
  String libDeleteBody(String title) {
    return '\"$title\" vai sumir para todos e o arquivo será excluído.';
  }

  @override
  String libSize(int kb) {
    return '$kb KB';
  }

  @override
  String libOpenFailed(String detail) {
    return 'Não foi possível abrir o arquivo: $detail';
  }

  @override
  String get libTitleRequired => 'Digite um título';

  @override
  String get dashLibrarySubtitle =>
      'Compartilhe os PDFs das lições com os participantes';

  @override
  String get homeLibrary => 'Biblioteca do retiro';

  @override
  String get photoPick => 'Escolher do aparelho';

  @override
  String get photoUploading => 'Enviando…';

  @override
  String photoUploadFailed(String detail) {
    return 'Não foi possível enviar a foto: $detail';
  }

  @override
  String get photoOrUrl => 'ou cole o endereço de uma imagem';

  @override
  String get cardTitle => 'Meu cartão';

  @override
  String get cardShareTitle => 'Compartilhar por QR';

  @override
  String get cardShareIntro =>
      'Troque versículos, motivos de oração e contatos com quem você conhece.';

  @override
  String get cardPhoto => 'Foto';

  @override
  String get cardChangePhoto => 'Trocar foto';

  @override
  String get cardVerseRef => 'Versículo';

  @override
  String get cardVerseRefHint => 'ex.: João 10:10';

  @override
  String get cardVerseText => 'Texto do versículo (opcional)';

  @override
  String get cardPrayerTopics => 'Motivos de oração · até 3';

  @override
  String get cardPrayerHint => 'Um por linha';

  @override
  String get cardContacts => 'Contatos — só aparece o que você ativar';

  @override
  String get cardChannels => 'Canais';

  @override
  String get cardEmail => 'E-mail';

  @override
  String get cardWhatsapp => 'WhatsApp';

  @override
  String get cardPhone => 'Telefone';

  @override
  String get cardInstagram => 'Instagram';

  @override
  String get cardX => 'X';

  @override
  String get cardYoutube => 'YouTube';

  @override
  String get cardJuniorLocked =>
      'Você tem 19 anos ou menos, então os contatos ficam desativados. Você ainda pode compartilhar versículo, motivos de oração e canais.';

  @override
  String get cardShowQr => 'Mostrar meu QR';

  @override
  String get cardScan => 'Ler um QR';

  @override
  String get cardQrHint => 'Quando alguém ler, seu cartão abre.';

  @override
  String get cardQrRotate => 'Criar um QR novo';

  @override
  String get cardQrRotateWarn =>
      'O código antigo para de funcionar na hora. Quem você já salvou continua na sua lista.';

  @override
  String get cardQrRotated => 'Um QR novo foi criado';

  @override
  String get cardScanUnsupported =>
      'Ler exige câmera. Use o celular ou abra o site no navegador.';

  @override
  String get cardScanPoint => 'Aponte para o QR da outra pessoa';

  @override
  String get cardSaveFriend => 'Salvar como amigo';

  @override
  String get cardDontSave => 'Não salvar';

  @override
  String get cardSaved => 'Salvo nos seus amigos';

  @override
  String get cardAlreadySaved => 'Já está nos seus amigos';

  @override
  String get cardSelfScan => 'Esse é o seu próprio cartão';

  @override
  String get cardExpiredCode => 'Esse código expirou ou não existe';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsEmpty =>
      'Ainda ninguém. Leia o QR de alguém depois de conversar.';

  @override
  String get friendsSearch => 'Busque por nome ou país…';

  @override
  String friendsMetOn(String date) {
    return 'Conheceram-se em $date';
  }

  @override
  String get friendsNote => 'Minha nota (só você vê)';

  @override
  String get friendsRemove => 'Remover da minha lista';

  @override
  String get friendsOtherPrograms => 'Outros retiros';

  @override
  String get cardPrivacyTitle => 'Configurações de compartilhamento';

  @override
  String get cardWhoCanSee => 'Quem pode abrir meu cartão';

  @override
  String get cardVisToken => 'Quem ler meu QR';

  @override
  String get cardVisProgram => 'Todos do mesmo retiro';

  @override
  String get cardVisProgramNote =>
      'Com isso ativado, é possível abrir seu cartão pela lista de participantes sem QR. Vem desativado.';

  @override
  String cardSavedBy(int count) {
    return 'Pessoas que salvaram meu cartão · $count';
  }

  @override
  String get cardSavedByEmpty => 'Ainda ninguém salvou seu cartão.';

  @override
  String get cardRevoke => 'Cortar';

  @override
  String get cardRevokeDone => 'Essa pessoa não vê mais seu cartão';

  @override
  String get cardSaveBack => 'Salvar também';

  @override
  String get cardOpenWhatsapp => 'WhatsApp';

  @override
  String get cardOpenEmail => 'E-mail';

  @override
  String get cardNoContacts => 'Essa pessoa não compartilhou contatos.';

  @override
  String get homeQrShare => 'Compartilhar por QR';

  @override
  String get homeQrShareSub =>
      'Seu cartão, seu QR e as pessoas que você conheceu';

  @override
  String get companionSameBranch => 'Mesma sede que a minha';

  @override
  String get companionSameBranchSub => 'Desative se for de outra sede';

  @override
  String get companionMustRegister =>
      'Cada acompanhante também precisa se inscrever por conta própria.';

  @override
  String get companionWhy =>
      'Você os adiciona aqui para ficarem no mesmo quarto. Se não fizer diferença ficarem em quartos separados, não é preciso adicionar.';

  @override
  String get homeAlsoAttending => 'Eu também participo';

  @override
  String get homeAlsoAttendingSub =>
      'Inscreva-se ou abra a inscrição que você já preencheu';

  @override
  String get homePickMyProgram => 'Entrar direto em um dos meus retiros';

  @override
  String get homeOrEnterUuid => 'Ou digite o UUID do retiro de outra pessoa';

  @override
  String chapterNoticeTitle(String leader) {
    return 'O líder da sua sede $leader criou um retiro';
  }

  @override
  String get chapterNoticeAsk => 'Você gostaria de participar?';

  @override
  String get chapterNoticeJoin => 'Sim, quero me inscrever';

  @override
  String get chapterNoticeLater => 'Agora não';

  @override
  String get cpFeeDescHint => 'ex.: quarto coletivo, 3 refeições';

  @override
  String get cpFeeDescLooksLikeAmount =>
      'Isto parece um valor. Escreva o número no campo de taxa à esquerda; este campo é para o que está incluído.';

  @override
  String get cpFeeNoneWarning =>
      'Não há taxa definida, então os participantes não veem a tela de taxa. Deixe vazio só se o retiro for gratuito.';

  @override
  String get rdyFeeTier => 'Nível de taxa';

  @override
  String feeBackfillTitle(int count) {
    return '$count pessoas não escolheram o nível de taxa';
  }

  @override
  String get feeBackfillWhy =>
      'Elas se inscreveram antes de a taxa ser definida, então não viram essa tela. O total delas não inclui a taxa do retiro.';

  @override
  String get feeBackfillAction => 'Definir todas como…';

  @override
  String feeBackfillConfirm(int count, String tier) {
    return 'Definir $count pessoas como $tier e recalcular seus totais? Quem já escolheu não é alterado.';
  }

  @override
  String feeBackfillDone(int count) {
    return '$count pessoas atualizadas';
  }

  @override
  String get feeBackfillNotSet =>
      'Esse nível ainda não tem valor. Defina a taxa primeiro.';

  @override
  String get studyLangMulti =>
      'Escolha todos os idiomas em que você pode estudar';

  @override
  String get studyLangPrimary => 'Principal';

  @override
  String get studyLangPrimaryNote =>
      'O primeiro que você escolher é o idioma principal: sua equipe de estudo é formada por ele. Os outros ajudam a alocar você quando uma equipe fica pequena.';

  @override
  String get regStepPickup => 'Transporte';

  @override
  String get pickupTitle => 'Precisa de carona até o local?';

  @override
  String get pickupBody =>
      'Você vem de dentro do país anfitrião, então não precisamos do seu voo. Só precisamos saber se buscamos você e onde.';

  @override
  String get pickupNeed => 'Preciso de carona';

  @override
  String get pickupNeedNo => 'Vou por conta própria';

  @override
  String get pickupFromLabel => 'Onde buscamos você?';

  @override
  String get pickupFromHint => 'ex.: rodoviária do Retiro, em frente à sede';

  @override
  String get pickupFromRequired => 'Escreva onde devemos buscar você';

  @override
  String get cpFeeMoveTitle => 'Os valores estão nos campos de descrição';

  @override
  String get cpFeeMoveBody =>
      'Como os campos de valor estão vazios, os participantes não veem a tela de taxa. Mover?';

  @override
  String get cpFeeMoveAction => 'Mover para os campos de taxa';

  @override
  String get cpFeeMoveDone => 'Pronto. Toque em Salvar para manter.';

  @override
  String get tblTitle => 'Detalhe';

  @override
  String tblCount(int count) {
    return '$count linhas';
  }

  @override
  String get tblEmpty => 'Não há nada para mostrar.';

  @override
  String get tblExportPdf => 'PDF';

  @override
  String get tblExportExcel => 'Excel';

  @override
  String tblExportFailed(String detail) {
    return 'Não foi possível exportar: $detail';
  }

  @override
  String get tblHint => 'Toque duas vezes para ver a lista';

  @override
  String get colGenderAge => 'Sexo / Idade';

  @override
  String get colStatus => 'Situação';

  @override
  String get colFlight => 'Voo de chegada';

  @override
  String get colPayment => 'Pagamento';

  @override
  String get colFee => 'Taxa';

  @override
  String get colLanguages => 'Idiomas';

  @override
  String get tblAllAttendees => 'Todos os participantes';

  @override
  String epPlanDocs(int count) {
    return 'Documentos do plano ($count)';
  }

  @override
  String get epPlanUpload => 'Enviar um PDF';

  @override
  String get epPlanName => 'Qual é este documento?';

  @override
  String get epPlanNameHint => 'ex.: Itinerário, Custos, Inscrição';

  @override
  String get epPlanRemove => 'Remover este documento';

  @override
  String epPlanFull(int max) {
    return 'Até $max documentos.';
  }

  @override
  String get tourPlanOpen => 'Abrir';

  @override
  String get tourOpenFailed => 'Não foi possível abrir; o link foi copiado.';

  @override
  String get dashStatTours => 'Inscrições nos tours';

  @override
  String get tblTourSignups => 'Inscrições nos tours';

  @override
  String get colTour => 'Tour';

  @override
  String get colSignups => 'Inscritos';

  @override
  String get colRemaining => 'Restam';

  @override
  String get colDeadline => 'Encerra';

  @override
  String get tourNoLimit => 'sem limite';

  @override
  String get tourNobody => 'Ainda ninguém se inscreveu';

  @override
  String tourSignupSummary(int signed) {
    return '$signed inscritos';
  }

  @override
  String get tblUnfinishedNote =>
      'Uma linha creme significa que ainda não concluiu o cadastro.';

  @override
  String get asnTabService => 'Serviço';

  @override
  String svcNeeded(int filled, int needed) {
    return '$filled de $needed';
  }

  @override
  String svcNoLimit(int filled) {
    return '$filled · sem meta';
  }

  @override
  String svcShort(int count) {
    return 'faltam $count';
  }

  @override
  String get svcNobody => 'Ainda ninguém';

  @override
  String get svcNominate => 'Pedir a alguém';

  @override
  String get svcPickPerson => 'A quem vamos pedir?';

  @override
  String svcAsked(String name) {
    return 'Pedimos a $name';
  }

  @override
  String get svcSetLead => 'Tornar responsável';

  @override
  String get svcLead => 'Responsável';

  @override
  String get svcConfirm => 'Confirmar';

  @override
  String get svcReject => 'Recusar';

  @override
  String get svcEditRoles => 'Adicionar funções · definir quantidades';

  @override
  String get svcAddRole => 'Adicionar uma função';

  @override
  String get svcRoleName => 'Nome da função';

  @override
  String get svcRoleNameHint => 'ex.: Guia do ônibus para Foz';

  @override
  String get svcNeedCount => 'Quantos?';

  @override
  String get svcNeedsApproval => 'Requer aprovação';

  @override
  String get svcStatusInvited => 'Aguardando resposta';

  @override
  String get svcStatusApplied => 'Se ofereceu';

  @override
  String get svcStatusApproval => 'Aguardando aprovação';

  @override
  String get svcStatusConfirmed => 'Confirmado';

  @override
  String get svcStatusRejected => 'Recusado';

  @override
  String get svcStatusDeclined => 'Disse que não';

  @override
  String get svcRoleSpecialSong => 'Canto especial';

  @override
  String get svcRoleMc => 'Apresentador';

  @override
  String get svcRolePickup => 'Traslados';

  @override
  String get svcRoleCleaning => 'Limpeza';

  @override
  String get svcRoleTourGuide => 'Guia do tour';

  @override
  String get svcRoleMealPrep => 'Preparar refeições';

  @override
  String get svcRoleLodgingBackup => 'Apoio de hospedagem';

  @override
  String get svcRoleRegistrationDesk => 'Mesa de inscrição';

  @override
  String get svcRoleInterpreter => 'Intérprete';

  @override
  String get svcRolePhotoVideo => 'Foto e vídeo';

  @override
  String get svcRoleMedical => 'Saúde';

  @override
  String get svcRoleGroupStudyLeader => 'Líder do grupo de estudo';

  @override
  String get svcRoleOther => 'Outro';

  @override
  String get svcInviteTitle => 'Pediram sua ajuda';

  @override
  String svcInviteBody(String role) {
    return 'Você poderia cuidar de $role?';
  }

  @override
  String get svcAccept => 'Sim, posso';

  @override
  String get svcDecline => 'Desculpe, não posso';

  @override
  String get svcThanks => 'Obrigado.';

  @override
  String get admTitle => 'Quem pode administrar';

  @override
  String get admSubtitle =>
      'Veem o painel, a lista de participantes e as atribuições.';

  @override
  String get admOwner => 'Criou';

  @override
  String get admAdd => 'Adicionar alguém';

  @override
  String get admPickPerson => 'Escolher da lista';

  @override
  String get admByEmail => 'Não está na lista? Use o e-mail';

  @override
  String get admEmailLabel => 'O e-mail com que faz login';

  @override
  String get admRemove => 'Remover';

  @override
  String admRemoveAsk(String name) {
    return 'Remover $name dos administradores?';
  }

  @override
  String admAdded(String name) {
    return '$name já pode administrar';
  }

  @override
  String get admOwnerLocked => 'Quem criou não pode ser removido.';

  @override
  String get dashAdmins => 'Administradores';

  @override
  String get dashAdminsSub => 'Dê acesso à lista e às atribuições';

  @override
  String get svcRolesTitle => 'Funções desta conferência';

  @override
  String svcRoleCount(int count, int max) {
    return '$count de $max funções';
  }

  @override
  String get svcSectionCustom => 'Funções que você criou';

  @override
  String get svcSectionBuiltIn => 'Funções prontas';

  @override
  String svcRoleFull(int max) {
    return 'Até $max funções.';
  }

  @override
  String get svcDeleteRole => 'Excluir esta função';

  @override
  String get svcNeedShort => 'precisa';

  @override
  String dashMoreCount(int count) {
    return 'Ver os outros $count →';
  }

  @override
  String get dashSeeAll => 'Abrir a tabela →';

  @override
  String get dashByTour => 'Ver tour a tour →';

  @override
  String get dashPreviewEmpty => 'Ainda nada';

  @override
  String get dashTourNobody => 'sem inscritos';

  @override
  String get dashTourRoom => 'há vaga';

  @override
  String get dashTourFull => 'lotado';

  @override
  String dashUnitPeopleShort(int count) {
    return '$count';
  }

  @override
  String epContacts(int count) {
    return 'Contatos no local ($count)';
  }

  @override
  String get epAddContact => 'Adicionar contato';

  @override
  String get epContactName => 'Nome';

  @override
  String get epContactPhone => 'Telefone';

  @override
  String get epRemoveContact => 'Remover este contato';

  @override
  String epContactsFull(int max) {
    return 'Até $max contatos.';
  }

  @override
  String get epPaymentWhen => 'Quando é pago?';

  @override
  String get epFeeWhen => 'Taxa da conferência';

  @override
  String get epTourWhen => 'Custo dos tours';

  @override
  String get epPrepaid => 'Antecipado';

  @override
  String get epOnsite => 'Na chegada';

  @override
  String get epPaymentNote =>
      'Se ambos forem pagos na chegada, o cartão de pagamentos some do painel.';

  @override
  String get dashStatPayments => 'Pagamentos';

  @override
  String get dashPayConfirmed => 'pago';

  @override
  String get dashPayPending => 'aguardando';

  @override
  String get dashPayNone => 'não pago';

  @override
  String get tblPayments => 'Pagamentos';

  @override
  String get setupExtraBed => 'Lugar extra';

  @override
  String get setupExtraBedHint =>
      'Cabe mais uma pessoa. Só é usada quando as camas normais acabam.';

  @override
  String asnRoomWithExtra(int used, int cap, int extra) {
    return '$used/$cap (+$extra)';
  }

  @override
  String setupExtraSeats(int count) {
    return 'extra $count';
  }

  @override
  String get dashStatVolunteers => 'Voluntários';

  @override
  String dashRoleFilled(int filled, int needed) {
    return '$filled/$needed';
  }

  @override
  String get dashOpenService => 'Abrir o painel de serviço →';

  @override
  String svcOffered(int count) {
    return 'Se ofereceram ($count)';
  }

  @override
  String get svcOfferedNote =>
      'O que disseram que podem fazer. Quem faz o quê continua sendo sua decisão.';

  @override
  String get svcCanDo => 'pode';

  @override
  String get svcCallSend => 'Pedir ajuda a todos';

  @override
  String svcCallSent(int short) {
    return 'Pedido · faltam $short';
  }

  @override
  String get svcCallClose => 'Parar de pedir';

  @override
  String get svcCallDone => 'Enviado a todos';

  @override
  String get svcCallTooSoon => 'Você já pediu há pouco. Espere algumas horas.';

  @override
  String get svcCallFilled => 'Esta função já está coberta.';

  @override
  String get svcCallNoTarget => 'Defina primeiro quantos você precisa.';

  @override
  String get svcOpenTitle => 'Precisamos de ajuda';

  @override
  String svcOpenBody(String role, int short) {
    return '$role — faltam $short';
  }

  @override
  String get svcIllDoIt => 'Eu faço';

  @override
  String get svcAppliedThanks => 'Obrigado. O organizador vai confirmar.';

  @override
  String get annTitle => 'Enviar um aviso';

  @override
  String get annSubtitle => 'Chega aos celulares, não só ao grupo';

  @override
  String get annBody => 'O que você quer dizer?';

  @override
  String get annSend => 'Enviar';

  @override
  String get annTo => 'Quem recebe';

  @override
  String get annToAll => 'Todos';

  @override
  String get annToRoom => 'Um quarto';

  @override
  String get annToGroup => 'Um grupo de estudo';

  @override
  String get annToUnsub => 'Não concluíram o cadastro';

  @override
  String get annToUnpaid => 'Ainda não pagaram';

  @override
  String get annPickRoom => 'Qual quarto?';

  @override
  String get annPickGroup => 'Qual grupo?';

  @override
  String annSent(int count) {
    return 'Enviado para $count aparelhos';
  }

  @override
  String get annPast => 'Avisos anteriores';

  @override
  String get annNoneYet => 'Você ainda não enviou nada';

  @override
  String get dashAnnounce => 'Avisar os participantes';

  @override
  String get dashAnnounceSub => 'A todos, ou só a um quarto ou grupo';

  @override
  String get dspPlanTitle => 'O que é preciso';

  @override
  String dspPlanNeed(int need, int add) {
    return '$need necessários · faltam $add';
  }

  @override
  String dspPlanOk(int have) {
    return '$have · coberto';
  }

  @override
  String dspPlanPeople(int count) {
    return '$count pessoas';
  }

  @override
  String dspMakeVans(int count) {
    return 'Criar $count van(s)';
  }

  @override
  String get dspPlanNone => 'Ainda não há horários';

  @override
  String get dspUnassignedFlight => 'sem van';

  @override
  String get schServiceLabel => 'Serviço necessário (opcional)';

  @override
  String get schServiceNone => 'Nenhum';

  @override
  String get schServiceHint =>
      'O lembrete dirá quantos faltam, só quando faltarem.';

  @override
  String svcAssignTo(String name) {
    return 'Pedir a $name que ajude com';
  }

  @override
  String get svcSuggested => 'combina com o que ofereceu';

  @override
  String get dashNotAssigned => 'ainda sem tarefa';

  @override
  String dashAssignedCount(int count) {
    return 'atribuído a $count';
  }

  @override
  String get asnNoRoomLeader => 'sem responsável de quarto';

  @override
  String asnRoomLeaderIs(String name) {
    return 'Responsável do quarto: $name';
  }

  @override
  String get asnNoGroupLeader => 'sem líder';

  @override
  String get svcMineTitle => 'Em que eu ajudo';

  @override
  String get tgOffer => 'Receber avisos também pelo Telegram';

  @override
  String get tgOpen => 'Abrir o Telegram';

  @override
  String get tgCheck => 'Já fiz';

  @override
  String get tgLinked => 'O Telegram está conectado';

  @override
  String get tgNotYet =>
      'Ainda não — abra o link, toque em Iniciar e tente de novo';

  @override
  String get tgUnlink => 'Desconectar';

  @override
  String svcAskThem(int count) {
    return 'Pedir ($count)';
  }

  @override
  String get epRoutes => 'Outras formas de chegar';

  @override
  String get epRoutesDesc =>
      'Nem todos chegam pelo mesmo aeroporto. Indique as outras rotas.';

  @override
  String get epRouteAirport => 'Aeroporto';

  @override
  String get epRouteNote => 'Como se chega de lá';

  @override
  String get epRouteNoteHint => 'ex.: Buenos Aires e 4 horas de ônibus';

  @override
  String get epAddRoute => 'Adicionar rota';

  @override
  String get epRemoveRoute => 'Remover esta rota';

  @override
  String get flightNoteLabel => 'Algo a acrescentar (opcional)';

  @override
  String get flightNoteHint => 'ex.: chego em EZE e sigo de ônibus';

  @override
  String get immCardOtherRoute => 'OTHER ROUTE / outra rota';

  @override
  String get svcWillConfirm => 'ofereceu-se para isto — atribuído na hora';

  @override
  String get svcWillAsk => 'não se ofereceu — vamos perguntar';

  @override
  String get setupGroupLanguage => 'Idioma em que este grupo estuda';

  @override
  String get setupAnyLanguage => 'Não definido';

  @override
  String get setupCoupleRooms => 'Quartos de casal · família';

  @override
  String get setupDormRooms => 'Quartos compartilhados';

  @override
  String get setupRoomsMadeName => 'Nome do quarto';

  @override
  String get setupGroupCapacityHint =>
      'Deixe vazio e a atribuição automática divide por igual';

  @override
  String get tblAmountDue => 'Valor a pagar';

  @override
  String get tblSubmittedHint => 'Ative se você anotou o formulário no papel';

  @override
  String get annToService => 'Uma equipe de serviço';

  @override
  String get annPickService => 'Para qual equipe?';

  @override
  String get payUnpaid => 'Não pago';

  @override
  String get payPartial => 'Pago parcial';

  @override
  String get payPaid => 'Pago';

  @override
  String get payPending => 'A verificar';

  @override
  String get tblAmountPaid => 'Valor recebido';

  @override
  String get sumWanting => 'Vão vir';

  @override
  String get sumCollected => 'Arrecadado';

  @override
  String get sumRemaining => 'Falta receber';

  @override
  String get ledgerTitle => 'Caixa';

  @override
  String get ledgerAdd => 'Adicionar lançamento';

  @override
  String get ledgerEmpty => 'Ainda não há nada anotado';

  @override
  String get ledgerIncome => 'Entrou';

  @override
  String get ledgerExpense => 'Saiu';

  @override
  String get ledgerWhat => 'Referente a';

  @override
  String get ledgerAmount => 'Valor';

  @override
  String get ledgerNote => 'Observação (opcional)';

  @override
  String get ledgerCollected => 'Inscrições recebidas';

  @override
  String get ledgerSupport => 'Apoio recebido';

  @override
  String get ledgerSpent => 'Gasto';

  @override
  String get ledgerBalance => 'Em caixa';

  @override
  String get ledgerExpected => 'Se todos pagarem';

  @override
  String ledgerOwedNote(String amount) {
    return 'Falta receber $amount';
  }

  @override
  String get dashLedgerSub => 'Apoios, gastos e o que sobra';

  @override
  String get ledgerAddExpense => 'Anotar gasto';

  @override
  String get ledgerAddIncome => 'Anotar apoio';

  @override
  String ledgerCount(int count) {
    return '$count lançamentos';
  }

  @override
  String ledgerLocalAmount(String code) {
    return 'Valor em $code';
  }

  @override
  String ledgerRate(String code, String base) {
    return '$code por 1 $base';
  }

  @override
  String get ledgerRateBlue => 'dólar blue de hoje — altere se usou outro';

  @override
  String get ledgerRateMarket => 'cotação de hoje — altere se usou outra';

  @override
  String get ledgerRateUnavailable =>
      'Não foi possível obter a cotação. Digite a que usou.';

  @override
  String get rosterNoName => 'Nome não preenchido';

  @override
  String rosterAccountName(String name) {
    return '$name (nome da conta)';
  }

  @override
  String get regNameFromAccount =>
      'Preenchido pela sua conta — corrija se não estiver certo';

  @override
  String get statByCountry => 'POR PAÍS';

  @override
  String get statByGender => 'POR SEXO';

  @override
  String get statByAge => 'POR IDADE';

  @override
  String get statUnknown => 'Não informado';

  @override
  String get statAgeUnder20 => 'Menos de 20';

  @override
  String get statAge70Plus => '70 ou mais';

  @override
  String statAgeDecade(int from, int to) {
    return '$from–$to';
  }

  @override
  String get tblFindName => 'Procurar um nome';

  @override
  String get statShowAll => 'Ver todos';

  @override
  String get commonClear => 'Limpar';

  @override
  String get scopeTransport => 'Traslados';

  @override
  String get scopeTransportHint =>
      'Vans, chegadas e saídas do aeroporto, pedidos de traslado';

  @override
  String get scopeRooms => 'Alojamento';

  @override
  String get scopeRoomsHint =>
      'Quartos e vagas, designação, responsável do quarto';

  @override
  String get scopeGroups => 'Estudo bíblico';

  @override
  String get scopeGroupsHint => 'Grupos, idioma e vagas, designação';

  @override
  String get scopeLedger => 'Dinheiro';

  @override
  String get scopeLedgerHint =>
      'Livro de contas, taxas recebidas, aprovar pagamentos e descontos';

  @override
  String get scopeService => 'Serviço';

  @override
  String get scopeServiceHint =>
      'Equipes de serviço, pedir ajuda, lista de voluntários';

  @override
  String get scopeRegistration => 'Inscrições';

  @override
  String get scopeRegistrationHint =>
      'Lista, marcar inscrição concluída, preencher por outro';

  @override
  String get scopeComms => 'Avisos';

  @override
  String get scopeCommsHint => 'Avisos e materiais';

  @override
  String get scopeSchedule => 'Programação';

  @override
  String get scopeScheduleHint => 'Programa e horários';

  @override
  String get scopeMedical => 'Saúde e segurança';

  @override
  String get scopeMedicalHint =>
      'Alertas SOS e dados de saúde. O mais privado que existe aqui.';

  @override
  String get scopeAll => 'Tudo — vê o mesmo que eu';

  @override
  String get scopeAllHint =>
      'Não precisa escolher um a um. Editar e apagar o retiro fica com quem o criou.';

  @override
  String get scopeTitle => 'Do que ele cuida?';

  @override
  String get scopeSaved => 'Salvo. Vamos avisar.';

  @override
  String get scopeNone => 'Escolha ao menos uma área';

  @override
  String get scopeEdit => 'Mudar as áreas';

  @override
  String get scopeNotYours => 'Essa área não está a seu cargo';

  @override
  String get epTourLodging => 'A hospedagem está incluída no passeio';

  @override
  String get epTourLodgingOn => 'As noites do passeio já estão pagas';

  @override
  String get epTourLodgingOff => 'Essas noites são cobradas como hotel';

  @override
  String get colHotel => 'Hotel';

  @override
  String rosterHotelNights(int n) {
    return '$n noite(s)';
  }
}
