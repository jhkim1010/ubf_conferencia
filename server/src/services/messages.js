// 서버가 내보내는 말의 번역 (055)
//
// 라우트는 한국어로 오류를 적는다(이 저장소의 관례). 그런데 그 문자열은
// 그대로 화면에 뜬다 — 앱이 ApiException.message 를 서른여섯 곳에서
// 보여 준다. 스페인어를 쓰는 공동 관리자에게는 화면 절반이 한국어로
// 나오는 셈이다.
//
// **라우트를 고치지 않는다.** 109 곳을 손대면 그중 하나는 반드시 빠뜨리고,
// 새 라우트를 쓸 때마다 또 잊는다. 응답이 나가는 길목 한 곳에서 갈아
// 끼운다 — 라우트는 계속 한국어로 적으면 되고, 여기 없는 말은 한국어
// 그대로 나간다(잘못 번역된 말보다 낫다).
//
// 키는 한국어 원문이다. 코드를 따로 두면 라우트마다 코드를 붙여야 하고,
// 그것이 곧 109 곳을 고치는 일이 된다.

const T = {
  // ── 자주 나오는 것 ────────────────────────────────────────
  '서버 오류': {
    es: 'Error del servidor',
    en: 'Server error',
    pt: 'Erro do servidor',
  },
  '서버 내부 오류': {
    es: 'Error interno del servidor',
    en: 'Internal server error',
    pt: 'Erro interno do servidor',
  },
  '권한 없음': { es: 'Sin permiso', en: 'Not allowed', pt: 'Sem permissão' },
  '권한이 없습니다': {
    es: 'No tiene permiso',
    en: 'You do not have permission',
    pt: 'Você não tem permissão',
  },
  '인증이 필요합니다': {
    es: 'Debe iniciar sesión',
    en: 'Sign in required',
    pt: 'É necessário entrar',
  },
  '인증 토큰이 없습니다': {
    es: 'Falta el token de sesión',
    en: 'No session token',
    pt: 'Falta o token de sessão',
  },
  '유효하지 않은 토큰입니다': {
    es: 'La sesión no es válida',
    en: 'Invalid session',
    pt: 'Sessão inválida',
  },
  '인증에 실패했습니다': {
    es: 'No se pudo iniciar sesión',
    en: 'Sign-in failed',
    pt: 'Falha ao entrar',
  },
  '카카오 인증에 실패했습니다': {
    es: 'No se pudo iniciar sesión con Kakao',
    en: 'Kakao sign-in failed',
    pt: 'Falha ao entrar com Kakao',
  },
  '사용자 없음': {
    es: 'Usuario no encontrado',
    en: 'User not found',
    pt: 'Usuário não encontrado',
  },
  '해당 이메일의 사용자를 찾을 수 없습니다': {
    es: 'No hay ningún usuario con ese correo',
    en: 'No user with that email',
    pt: 'Nenhum usuário com esse e-mail',
  },
  '리더가 아닙니다': {
    es: 'No es responsable',
    en: 'Not a leader',
    pt: 'Não é responsável',
  },
  '관리자 권한이 필요합니다': {
    es: 'Se requiere permiso de responsable',
    en: 'Admin permission required',
    pt: 'Requer permissão de responsável',
  },
  'director 권한이 필요합니다': {
    es: 'Se requiere permiso de director',
    en: 'Director permission required',
    pt: 'Requer permissão de diretor',
  },
  '해당 프로그램의 관리자 권한이 없습니다': {
    es: 'No es responsable de esta conferencia',
    en: 'You do not manage this conference',
    pt: 'Você não administra esta conferência',
  },
  '시도가 너무 잦습니다. 잠시 후 다시 시도해 주세요.': {
    es: 'Demasiados intentos. Espere un momento y vuelva a intentar.',
    en: 'Too many attempts. Wait a moment and try again.',
    pt: 'Muitas tentativas. Aguarde um momento e tente de novo.',
  },
  '요청이 너무 많습니다.': {
    es: 'Demasiadas solicitudes.',
    en: 'Too many requests.',
    pt: 'Muitas solicitações.',
  },

  // ── 못 찾음 ──────────────────────────────────────────────
  '프로그램을 찾을 수 없습니다': {
    es: 'No se encontró la conferencia',
    en: 'Conference not found',
    pt: 'Conferência não encontrada',
  },
  '수양회를 찾을 수 없습니다': {
    es: 'No se encontró la conferencia',
    en: 'Conference not found',
    pt: 'Conferência não encontrada',
  },
  '등록을 찾을 수 없습니다': {
    es: 'No se encontró la inscripción',
    en: 'Registration not found',
    pt: 'Inscrição não encontrada',
  },
  '등록 정보가 없습니다': {
    es: 'No hay inscripción',
    en: 'No registration',
    pt: 'Sem inscrição',
  },
  '참가자를 찾을 수 없습니다': {
    es: 'No se encontró al participante',
    en: 'Participant not found',
    pt: 'Participante não encontrado',
  },
  '방을 찾을 수 없습니다': {
    es: 'No se encontró el cuarto',
    en: 'Room not found',
    pt: 'Quarto não encontrado',
  },
  '숙소를 찾을 수 없습니다': {
    es: 'No se encontró el alojamiento',
    en: 'Room not found',
    pt: 'Alojamento não encontrado',
  },
  '조를 찾을 수 없습니다': {
    es: 'No se encontró el grupo',
    en: 'Group not found',
    pt: 'Grupo não encontrado',
  },
  '밴을 찾을 수 없습니다': {
    es: 'No se encontró la combi',
    en: 'Van not found',
    pt: 'Van não encontrada',
  },
  '일정을 찾을 수 없습니다': {
    es: 'No se encontró el horario',
    en: 'Schedule item not found',
    pt: 'Item da programação não encontrado',
  },
  '자료를 찾을 수 없습니다': {
    es: 'No se encontró el material',
    en: 'File not found',
    pt: 'Material não encontrado',
  },
  '항목을 찾을 수 없습니다': {
    es: 'No se encontró el movimiento',
    en: 'Entry not found',
    pt: 'Lançamento não encontrado',
  },
  '신청을 찾을 수 없습니다': {
    es: 'No se encontró la solicitud',
    en: 'Application not found',
    pt: 'Solicitação não encontrada',
  },
  '요청을 찾을 수 없습니다': {
    es: 'No se encontró la solicitud',
    en: 'Request not found',
    pt: 'Solicitação não encontrada',
  },
  '처리할 요청을 찾을 수 없습니다': {
    es: 'No hay ninguna solicitud pendiente',
    en: 'No pending request',
    pt: 'Nenhuma solicitação pendente',
  },
  '부탁을 찾을 수 없습니다': {
    es: 'No se encontró el pedido',
    en: 'Request not found',
    pt: 'Pedido não encontrado',
  },
  '대상을 찾을 수 없습니다': {
    es: 'No se encontró el destinatario',
    en: 'Target not found',
    pt: 'Destinatário não encontrado',
  },
  'SOS 알림을 찾을 수 없습니다': {
    es: 'No se encontró la alerta SOS',
    en: 'SOS alert not found',
    pt: 'Alerta SOS não encontrado',
  },
  '명함이 없습니다': {
    es: 'No hay tarjeta',
    en: 'No card',
    pt: 'Sem cartão',
  },
  '없습니다': { es: 'No existe', en: 'Not found', pt: 'Não existe' },

  // ── 먼저 해야 할 일 ──────────────────────────────────────
  '먼저 등록을 진행해 주세요': {
    es: 'Primero complete su inscripción',
    en: 'Please register first',
    pt: 'Primeiro faça sua inscrição',
  },
  '먼저 등록해 주십시오': {
    es: 'Primero inscríbase',
    en: 'Please register first',
    pt: 'Primeiro inscreva-se',
  },
  '이 프로그램에 먼저 등록하세요': {
    es: 'Primero inscríbase en esta conferencia',
    en: 'Register for this conference first',
    pt: 'Primeiro inscreva-se nesta conferência',
  },
  '등록 정보를 먼저 제출해 주세요': {
    es: 'Primero envíe su inscripción',
    en: 'Submit your registration first',
    pt: 'Primeiro envie sua inscrição',
  },
  '먼저 기사·차량(밴)을 등록하세요': {
    es: 'Primero cargue conductores y combis',
    en: 'Add drivers and vans first',
    pt: 'Primeiro cadastre motoristas e vans',
  },
  '파일을 먼저 올려 주십시오': {
    es: 'Primero suba el archivo',
    en: 'Upload the file first',
    pt: 'Primeiro envie o arquivo',
  },
  '이미 리더로 등록되어 있습니다': {
    es: 'Ya está registrado como responsable',
    en: 'Already registered as a leader',
    pt: 'Já está registrado como responsável',
  },
  '이 이메일은 이미 다른 리더 계정에 등록되어 있습니다': {
    es: 'Ese correo ya pertenece a otro responsable',
    en: 'That email already belongs to another leader',
    pt: 'Esse e-mail já pertence a outro responsável',
  },
  '동일한 이름과 시작일의 프로그램이 이미 존재합니다': {
    es: 'Ya existe una conferencia con ese nombre y fecha',
    en: 'A conference with that name and date already exists',
    pt: 'Já existe uma conferência com esse nome e data',
  },
  '이미 처리된 부탁입니다': {
    es: 'Ese pedido ya fue respondido',
    en: 'That request was already answered',
    pt: 'Esse pedido já foi respondido',
  },

  // ── 규칙 ─────────────────────────────────────────────────
  '그 방에 배정된 사람만 방장이 될 수 있습니다': {
    es: 'Solo alguien asignado al cuarto puede ser encargado',
    en: 'Only someone assigned to the room can lead it',
    pt: 'Só quem está no quarto pode ser o responsável',
  },
  '단체실은 같은 성별만 배정할 수 있습니다': {
    es: 'Los cuartos compartidos son de un solo género',
    en: 'Shared rooms take one gender only',
    pt: 'Quartos compartilhados são de um só gênero',
  },
  '성별이 다른 사람과 같은 방을 쓰려면 동행(가족) 관계여야 합니다': {
    es: 'Para compartir cuarto entre géneros deben ser familia',
    en: 'Sharing a room across genders requires a family link',
    pt: 'Para dividir quarto entre gêneros é preciso ser família',
  },
  '방 정원이 가득 찼습니다': {
    es: 'El cuarto está lleno',
    en: 'The room is full',
    pt: 'O quarto está cheio',
  },
  '밴 정원이 가득 찼습니다': {
    es: 'La combi está llena',
    en: 'The van is full',
    pt: 'A van está cheia',
  },
  '동반자는 최대 15명까지입니다': {
    es: 'Hasta 15 acompañantes',
    en: 'Up to 15 companions',
    pt: 'Até 15 acompanhantes',
  },
  '자기 자신은 지목할 수 없습니다': {
    es: 'No puede elegirse a usted mismo',
    en: 'You cannot pick yourself',
    pt: 'Você não pode escolher a si mesmo',
  },
  '픽업은 운전면허 보유자만 신청할 수 있습니다': {
    es: 'Solo con licencia de conducir puede anotarse para buscar gente',
    en: 'Only licensed drivers can sign up for pickup',
    pt: 'Só quem tem carteira pode se inscrever para buscar',
  },
  '신청 대상이 아닙니다': {
    es: 'No corresponde a este caso',
    en: 'Not eligible',
    pt: 'Não elegível',
  },
  '이 수양회에 없는 역할입니다': {
    es: 'Ese servicio no existe en esta conferencia',
    en: 'That role does not exist in this conference',
    pt: 'Esse serviço não existe nesta conferência',
  },
  '역할이 올바르지 않습니다': {
    es: 'El servicio no es válido',
    en: 'That role is not valid',
    pt: 'O serviço não é válido',
  },
  '수양회가 시작된 후에는 투어 옵션을 수정할 수 없습니다': {
    es: 'No se pueden cambiar los paseos una vez comenzada la conferencia',
    en: 'Tours cannot be changed once the conference has started',
    pt: 'Os passeios não podem mudar depois que a conferência começa',
  },
  '수양회를 만든 사람만 관리자를 세울 수 있습니다': {
    es: 'Solo quien creó la conferencia puede nombrar responsables',
    en: 'Only the conference creator can appoint managers',
    pt: 'Só quem criou a conferência pode nomear responsáveis',
  },
  '수양회를 만든 사람은 뺄 수 없습니다': {
    es: 'No se puede quitar a quien creó la conferencia',
    en: 'The conference creator cannot be removed',
    pt: 'Não é possível remover quem criou a conferência',
  },
  '등록자가 있는 수양회입니다. 삭제하려면 수양회 이름을 입력하십시오': {
    es: 'Hay inscriptos. Para borrarla, escriba el nombre de la conferencia',
    en: 'People are registered. Type the conference name to delete it',
    pt: 'Há inscritos. Digite o nome da conferência para excluí-la',
  },
  '보낼 대상이 올바르지 않습니다': {
    es: 'El destinatario no es válido',
    en: 'That audience is not valid',
    pt: 'O destinatário não é válido',
  },
  '보낼 내용이 없습니다': {
    es: 'No hay nada que enviar',
    en: 'Nothing to send',
    pt: 'Não há nada para enviar',
  },
  '만료되었거나 없는 코드입니다': {
    es: 'El código no existe o venció',
    en: 'That code is missing or expired',
    pt: 'O código não existe ou expirou',
  },
  '올바른 코드가 아닙니다': {
    es: 'El código no es válido',
    en: 'That code is not valid',
    pt: 'O código não é válido',
  },
  '저장할 수 없습니다': {
    es: 'No se pudo guardar',
    en: 'Could not save',
    pt: 'Não foi possível salvar',
  },
  '내 명함입니다': {
    es: 'Es su propia tarjeta',
    en: 'That is your own card',
    pt: 'É o seu próprio cartão',
  },

  // ── 값이 잘못됨 ──────────────────────────────────────────
  '금액이 올바르지 않습니다': {
    es: 'El monto no es válido',
    en: 'That amount is not valid',
    pt: 'O valor não é válido',
  },
  '항목·금액·내용을 확인해 주십시오': {
    es: 'Revise el tipo, el monto y el concepto',
    en: 'Check the kind, the amount and what it was for',
    pt: 'Verifique o tipo, o valor e a referência',
  },
  '참가비는 0 이상의 숫자여야 합니다': {
    es: 'La inscripción debe ser un número de 0 o más',
    en: 'The fee must be a number of 0 or more',
    pt: 'A inscrição deve ser um número de 0 ou mais',
  },
  '할인 금액은 0 이상의 숫자여야 합니다': {
    es: 'El descuento debe ser un número de 0 o más',
    en: 'The discount must be a number of 0 or more',
    pt: 'O desconto deve ser um número de 0 ou mais',
  },
  '승인하려면 할인 금액이 필요합니다': {
    es: 'Para aprobar hace falta el monto del descuento',
    en: 'Approving needs the discount amount',
    pt: 'Para aprovar é preciso o valor do desconto',
  },
  '그 등급의 참가비가 정해져 있지 않습니다': {
    es: 'Esa categoría no tiene precio definido',
    en: 'That tier has no fee set',
    pt: 'Essa categoria não tem valor definido',
  },
  '통화는 ISO 4217 코드(대문자 세 글자)여야 합니다': {
    es: 'La moneda debe ser un código ISO 4217 (tres letras)',
    en: 'Currency must be an ISO 4217 code (three letters)',
    pt: 'A moeda deve ser um código ISO 4217 (três letras)',
  },
  'capacity는 1 이상의 정수여야 합니다': {
    es: 'La capacidad debe ser 1 o más',
    en: 'Capacity must be 1 or more',
    pt: 'A capacidade deve ser 1 ou mais',
  },
  'count는 1~100 사이여야 합니다': {
    es: 'La cantidad debe estar entre 1 y 100',
    en: 'Count must be between 1 and 100',
    pt: 'A quantidade deve estar entre 1 e 100',
  },
  'count는 1~200 사이여야 합니다': {
    es: 'La cantidad debe estar entre 1 y 200',
    en: 'Count must be between 1 and 200',
    pt: 'A quantidade deve estar entre 1 e 200',
  },
  '소수 인원 방침이 올바르지 않습니다': {
    es: 'La política para grupos chicos no es válida',
    en: 'The small-group policy is not valid',
    pt: 'A política para grupos pequenos não é válida',
  },
  '지부 정보가 올바르지 않습니다': {
    es: 'Los datos del capítulo no son válidos',
    en: 'The chapter details are not valid',
    pt: 'Os dados do capítulo não são válidos',
  },
  '출발 상태가 올바르지 않습니다': {
    es: 'El estado de salida no es válido',
    en: 'That departure status is not valid',
    pt: 'O status de partida não é válido',
  },
  '지연된 출발 시각을 함께 적어 주십시오': {
    es: 'Indique también la nueva hora de salida',
    en: 'Give the new departure time as well',
    pt: 'Informe também o novo horário de saída',
  },
  '텔레그램 봇 토큰 형식이 올바르지 않습니다 (예: 123456789:AA...)': {
    es: 'El token del bot de Telegram no tiene el formato correcto (ej.: 123456789:AA...)',
    en: 'The Telegram bot token is malformed (e.g. 123456789:AA...)',
    pt: 'O token do bot do Telegram está mal formatado (ex.: 123456789:AA...)',
  },
  'JPEG·PNG·WebP 사진 또는 PDF 만 올릴 수 있습니다': {
    es: 'Solo se pueden subir fotos JPEG, PNG o WebP, o archivos PDF',
    en: 'Only JPEG, PNG or WebP photos, or PDF files',
    pt: 'Somente fotos JPEG, PNG ou WebP, ou arquivos PDF',
  },
  '파일 데이터가 없습니다': {
    es: 'No llegó el archivo',
    en: 'No file data',
    pt: 'O arquivo não chegou',
  },
  'action 은 confirm 또는 reject 여야 합니다': {
    es: 'La acción debe ser confirmar o rechazar',
    en: 'Action must be confirm or reject',
    pt: 'A ação deve ser confirmar ou rejeitar',
  },
  'action은 accept 또는 decline': {
    es: 'La acción debe ser aceptar o rechazar',
    en: 'Action must be accept or decline',
    pt: 'A ação deve ser aceitar ou recusar',
  },
  'status 는 approved/rejected/requested 중 하나여야 합니다': {
    es: 'El estado debe ser aprobado, rechazado o solicitado',
    en: 'Status must be approved, rejected or requested',
    pt: 'O status deve ser aprovado, rejeitado ou solicitado',
  },

  // ── 빠진 값 ──────────────────────────────────────────────
  '프로그램 이름과 장소는 필수입니다': {
    es: 'Faltan el nombre y el lugar de la conferencia',
    en: 'Conference name and place are required',
    pt: 'Faltam o nome e o local da conferência',
  },
  '이름이 필요합니다': {
    es: 'Falta el nombre',
    en: 'A name is required',
    pt: 'Falta o nome',
  },
  'name이 필요합니다': {
    es: 'Falta el nombre',
    en: 'A name is required',
    pt: 'Falta o nome',
  },
  '제목이 필요합니다': {
    es: 'Falta el título',
    en: 'A title is required',
    pt: 'Falta o título',
  },
  'title과 scheduledAt이 필요합니다': {
    es: 'Faltan el título y la hora',
    en: 'Title and time are required',
    pt: 'Faltam o título e o horário',
  },
  'name과 capacity가 필요합니다': {
    es: 'Faltan el nombre y la capacidad',
    en: 'Name and capacity are required',
    pt: 'Faltam o nome e a capacidade',
  },
  'namePattern, count, capacity가 필요합니다': {
    es: 'Faltan el patrón de nombre, la cantidad y la capacidad',
    en: 'Name pattern, count and capacity are required',
    pt: 'Faltam o padrão de nome, a quantidade e a capacidade',
  },
  'name, age, region 모두 필요합니다': {
    es: 'Faltan nombre, edad y región',
    en: 'Name, age and region are all required',
    pt: 'Faltam nome, idade e região',
  },
  'roomId와 registrationId가 필요합니다': {
    es: 'Faltan el cuarto y la persona',
    en: 'Room and person are required',
    pt: 'Faltam o quarto e a pessoa',
  },
  'groupId와 registrationId가 필요합니다': {
    es: 'Faltan el grupo y la persona',
    en: 'Group and person are required',
    pt: 'Faltam o grupo e a pessoa',
  },
  'registrationId 가 없습니다': {
    es: 'Falta la persona',
    en: 'The person is missing',
    pt: 'Falta a pessoa',
  },
  'registrationId 또는 companionId가 필요합니다': {
    es: 'Falta la persona o el acompañante',
    en: 'A person or companion is required',
    pt: 'Falta a pessoa ou o acompanhante',
  },
  'registrationId 또는 companionId 중 하나만 필요합니다': {
    es: 'Indique la persona o el acompañante, no ambos',
    en: 'Give either the person or the companion, not both',
    pt: 'Informe a pessoa ou o acompanhante, não ambos',
  },
  'programId가 없습니다': {
    es: 'Falta la conferencia',
    en: 'The conference is missing',
    pt: 'Falta a conferência',
  },
  'programId, situationType이 필요합니다': {
    es: 'Faltan la conferencia y el tipo de situación',
    en: 'Conference and situation type are required',
    pt: 'Faltam a conferência e o tipo de situação',
  },
  'direction과 airport는 필수입니다': {
    es: 'Faltan el sentido y el aeropuerto',
    en: 'Direction and airport are required',
    pt: 'Faltam o sentido e o aeroporto',
  },
  'items 배열이 필요합니다': {
    es: 'Falta la lista de ítems',
    en: 'A list of items is required',
    pt: 'Falta a lista de itens',
  },
  'toRegistrationId와 유효한 kind가 필요합니다': {
    es: 'Faltan la persona y un tipo válido',
    en: 'A person and a valid kind are required',
    pt: 'Faltam a pessoa e um tipo válido',
  },
  'email 또는 registrationId 가 필요합니다': {
    es: 'Falta el correo o la inscripción',
    en: 'An email or a registration is required',
    pt: 'Falta o e-mail ou a inscrição',
  },
  'telegramChatId가 필요합니다': {
    es: 'Falta el chat de Telegram',
    en: 'The Telegram chat is missing',
    pt: 'Falta o chat do Telegram',
  },
  '이름을 적어 주세요': {
    es: 'Escriba su nombre',
    en: 'Please enter your name',
    pt: 'Escreva seu nome',
  },
  '이 분야는 맡지 않으셨습니다': {
    es: 'Esta área no está a su cargo',
    en: 'That area is not yours to look after',
    pt: 'Essa área não está a seu cargo',
  },
  '사용자 없음': {
    es: 'Usuario no encontrado',
    en: 'User not found',
    pt: 'Usuário não encontrado',
  },
  'accessToken이 필요합니다': {
    es: 'Falta el accessToken',
    en: 'accessToken is required',
    pt: 'Falta o accessToken',
  },
  'idToken 또는 accessToken이 필요합니다': {
    es: 'Falta idToken o accessToken',
    en: 'idToken or accessToken is required',
    pt: 'Falta idToken ou accessToken',
  },
};

// ── 빈칸이 들어가는 말 ────────────────────────────────────────
//
// 라우트가 백틱으로 짓는 오류가 있다 — `"${o.name}" 투어는 정원이
// 마감되었습니다`. 런타임 문자열은 투어 이름마다 달라지므로 위의 표에서
// 절대 찾을 수 없고, **번역 없이 한국어 그대로 나갔다.** 검사가 리터럴만
// 보고 있어서 조용히 통과했다.
//
// 열쇠의 `{}` 는 라우트의 `${...}` 자리다. 그 자리에 있던 값(투어 이름,
// 사람 수, 용량)은 번역하지 않고 그대로 옮긴다 — 고유명사와 숫자다.
const P = {
  '"{}" 투어는 신청이 마감되었습니다': {
    es: 'La excursión "{}" ya cerró las inscripciones',
    en: 'Sign-ups for the "{}" tour are closed',
    pt: 'As inscrições para o passeio "{}" estão encerradas',
  },
  '"{}" 투어는 정원이 마감되었습니다': {
    es: 'La excursión "{}" ya no tiene lugares',
    en: 'The "{}" tour is full',
    pt: 'O passeio "{}" está lotado',
  },
  '사용할 수 없는 항목입니다: {}': {
    es: 'Ese ítem no está disponible: {}',
    en: 'That item is not available: {}',
    pt: 'Esse item não está disponível: {}',
  },
  '이미 배정된 {}명보다 작을 수 없습니다': {
    es: 'No puede ser menos que las {} personas ya asignadas',
    en: 'Cannot be fewer than the {} people already assigned',
    pt: 'Não pode ser menor que as {} pessoas já designadas',
  },
  '파일이 너무 큽니다 (사진 {}KB · PDF {}MB 까지)': {
    es: 'El archivo es muy grande (hasta {} KB en fotos · {} MB en PDF)',
    en: 'That file is too big (up to {} KB for photos · {} MB for PDF)',
    pt: 'O arquivo é muito grande (até {} KB em fotos · {} MB em PDF)',
  },
};

// 열쇠를 정규식으로 굽는다. `{}` 는 아무 값이나, 나머지는 글자 그대로.
const COMPILED = Object.entries(P).map(([shape, row]) => ({
  shape,
  re: new RegExp(
    '^' +
      shape
        .split('{}')
        .map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
        .join('(.+?)') +
      '$',
  ),
  row,
}));

/// 빈칸 있는 말을 맞춰 본다. 못 맞추면 null.
function fillIn(text, lang) {
  for (const { re, row } of COMPILED) {
    const m = re.exec(text);
    if (!m) continue;
    const out = row[lang];
    if (!out) return null;
    let i = 1;
    return out.replace(/\{\}/g, () => m[i++] ?? '');
  }
  return null;
}

/// Accept-Language 에서 쓸 언어를 고른다.
///
/// 아는 언어가 아니면 한국어 그대로 둔다 — 라우트가 적은 말이 원본이다.
export function pickLanguage(header) {
  const raw = String(header ?? '').toLowerCase();
  for (const part of raw.split(',')) {
    const tag = part.split(';')[0].trim();
    const base = tag.split('-')[0];
    if (base === 'ko') return 'ko';
    if (base === 'es' || base === 'en' || base === 'pt') return base;
  }
  return 'ko';
}

/// 한국어 원문을 그 언어로. 모르는 말이면 원문 그대로.
export function translate(text, lang) {
  if (lang === 'ko' || !lang) return text;
  const row = T[text];
  if (row) return row[lang] ?? text;
  // 표에 없으면 빈칸 있는 말인지 본다.
  return fillIn(text, lang) ?? text;
}

/// 번역표에 있는 말의 수. 검사에서 쓴다.
export const MESSAGE_COUNT = Object.keys(T).length + Object.keys(P).length;

export const MESSAGES = T;
export const PATTERNS = P;
