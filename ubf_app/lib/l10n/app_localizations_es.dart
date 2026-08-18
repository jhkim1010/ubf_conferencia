// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mana';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Usar el idioma del dispositivo';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionAdd => 'Añadir';

  @override
  String get actionNext => 'Siguiente';

  @override
  String get actionPrevious => 'Atrás';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionLogout => 'Cerrar sesión';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonError => 'Algo salió mal';

  @override
  String get commonRequired => 'Obligatorio';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get setupTitle => 'Preparación';

  @override
  String get setupTabRooms => 'Alojamiento';

  @override
  String get setupTabGroups => 'Grupos de estudio';

  @override
  String get appTagline => 'Sistema de registro del retiro';

  @override
  String get authSignInGoogle => 'Iniciar sesión con Google';

  @override
  String get authSignInKakao => 'Iniciar sesión con Kakao';

  @override
  String get authSignInDev => 'Inicio de prueba (dev@test.com)';

  @override
  String get authTermsNotice =>
      'Al iniciar sesión, aceptas los Términos del Servicio.';

  @override
  String authGoogleFailed(String error) {
    return 'Error al iniciar sesión con Google: $error';
  }

  @override
  String authKakaoFailed(String error) {
    return 'Error al iniciar sesión con Kakao: $error';
  }

  @override
  String authDevFailed(String error) {
    return 'Error en el inicio de prueba: $error';
  }

  @override
  String get profileTitle => 'Configuración de perfil';

  @override
  String get profileSubtitle =>
      'Ingresa la información básica para el registro.\nSolo necesitas hacerlo una vez.';

  @override
  String get profileNameLabel => 'Nombre *';

  @override
  String get profileNameHint => 'Ingresa tu nombre real';

  @override
  String get profileNameRequired => 'Ingresa tu nombre';

  @override
  String get profileAgeLabel => 'Edad *';

  @override
  String get profileAgeHint => 'ej. 28';

  @override
  String get profileAgeInvalid => 'Ingresa una edad válida';

  @override
  String get profileRegionLabel => 'Región *';

  @override
  String get profileRegionHint => 'ej. Seúl, Nueva York, Toronto...';

  @override
  String get profileRegionRequired => 'Ingresa tu región';

  @override
  String get profileSaveStart => 'Guardar y comenzar';

  @override
  String profileSaveFailed(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get homeLogoutConfirmBody =>
      '¿Deseas cerrar sesión?\nPuedes iniciar sesión con otra cuenta.';

  @override
  String get homeDirectorMode => 'Modo director';

  @override
  String get homeManageMenu => 'Gestión';

  @override
  String get homeCreateProgram => 'Crear programa';

  @override
  String get homeCreateProgramSub => 'Genera un UUID y configura un programa';

  @override
  String get homeProgramList => 'Mis programas';

  @override
  String get homeProgramListDirectorSub => 'Gestiona los programas que creaste';

  @override
  String get homeProgramListAdminSub => 'Gestiona tus programas asignados';

  @override
  String get homeAssignAdmins => 'Asignar administradores';

  @override
  String get homeAssignAdminsSub => 'Designa un administrador por programa';

  @override
  String get homeDirectorInfo =>
      'Un director gestiona todos los programas y puede asignar administradores.';

  @override
  String get homeAdminMode => 'Modo administrador';

  @override
  String get homeAdminInfo =>
      'Después de crear un programa, comparte su UUID con los participantes.';

  @override
  String get homeJoinTitle => 'Unirse a un programa';

  @override
  String get homeJoinSub =>
      'Ingresa el UUID que te dio tu líder para unirte a un programa.';

  @override
  String get homeUuidLabel => 'UUID del programa';

  @override
  String get homeJoinButton => 'Unirse';

  @override
  String get homeRecentPrograms => 'Unido recientemente';

  @override
  String get homeRemoveFromList => 'Quitar de la lista';

  @override
  String get homeBecomeLeader => '¿Eres líder? Cambiar a modo líder';

  @override
  String get homeLeaderCheckTitle => 'Verificación de líder';

  @override
  String homeLeaderCheckBody(String email) {
    return 'El correo con el que iniciaste sesión ($email) está registrado como líder de este capítulo:';
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
      '¿Deseas registrarte como líder de capítulo?';

  @override
  String get homeLeaderDeclineParticipant => 'No, continuar como participante';

  @override
  String get homeLeaderConfirmRegister => 'Sí, registrarme como líder';

  @override
  String get commonSaved => 'Guardado';

  @override
  String commonErrorDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get sectionDisabled => 'Esta sección está desactivada';

  @override
  String get flightSkipTitle => 'Ingreso de vuelo omitido';

  @override
  String flightSkipBody(String dir) {
    return 'Vives en el país anfitrión, por lo que se omite el ingreso del vuelo de $dir. Si viajas en avión, agrégalo abajo.';
  }

  @override
  String get flightSkipAdd => 'Agregar datos del vuelo';

  @override
  String get flightSkipCollapse => 'Omitir vuelo';

  @override
  String get regTitle => 'Registro';

  @override
  String get regInvalidProgram => 'UUID de programa no válido';

  @override
  String get regScheduleTooltip => 'Horario del programa';

  @override
  String get regSaveDraft => 'Guardar borrador';

  @override
  String get regReviewSummary => 'Revisar resumen';

  @override
  String get regStepPersonal => 'Información personal';

  @override
  String get regStepArrival => 'Vuelo de llegada';

  @override
  String get regStepDeparture => 'Vuelo de salida';

  @override
  String get regStepFood => 'Comidas';

  @override
  String get regStepOptions => 'Tours / opciones';

  @override
  String get regStepRoommate => 'Compañero de cuarto';

  @override
  String get regStepVolunteer => 'Voluntariado';

  @override
  String get roommateQuestion =>
      '¿Hay alguien con quien te gustaría compartir habitación?';

  @override
  String get roommateHelp =>
      'Ingresa el nombre (nombre bíblico o nombre real) de la persona con quien deseas compartir habitación.\nHaremos lo posible por respetarlo.';

  @override
  String get roommateFieldLabel => 'Preferencia de compañero (opcional)';

  @override
  String get roommateFieldHint =>
      'ej. Pedro, Juan (misma habitación)\no escribe \"Ninguno\"';

  @override
  String get roommateNotice =>
      'La asignación de compañeros puede ajustarse a criterio del líder.';

  @override
  String get optionsNone => 'Este programa no tiene opciones especiales';

  @override
  String get optionsSelectPrompt =>
      'Selecciona los programas en los que participarás (varios permitidos)';

  @override
  String get optionsFree => 'Gratis';

  @override
  String get optionsSelectedTotal => 'Total de opciones seleccionadas';

  @override
  String get genderMale => 'Hombre';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get regContinent => 'Continente *';

  @override
  String get regContinentHint => 'Selecciona un continente';

  @override
  String get regNation => 'País *';

  @override
  String get regNationHint => 'Selecciona un país';

  @override
  String get regNationDisabled => 'Selecciona primero un continente';

  @override
  String get regChapter => 'Capítulo *';

  @override
  String get regChapterHint => 'Selecciona un capítulo';

  @override
  String get regChapterNoneHint =>
      'No hay capítulos registrados para este país. Ingrésalo manualmente abajo.';

  @override
  String get regChapterManualHint =>
      'Si no está en la lista, ingrésalo manualmente abajo';

  @override
  String get regBranch => 'Nombre del capítulo *';

  @override
  String get regBranchHint => 'ej. Tokio, Chicago';

  @override
  String get regRealName => 'Nombre real *';

  @override
  String get regBibleName => 'Nombre bíblico';

  @override
  String get regBibleNameHint => 'ej. Pedro, María';

  @override
  String get regGender => 'Género';

  @override
  String get regAge => 'Edad *';

  @override
  String get foodMedicalTitle => 'Condiciones médicas';

  @override
  String get foodMedicalHint =>
      'Indica condiciones como diabetes, hipertensión, alergias (deja en blanco si no hay)';

  @override
  String get foodRestrictionTitle => 'Alimentos que no puedes comer';

  @override
  String get foodRestrictionHelp => 'Elige abajo o escribe el tuyo';

  @override
  String get foodRestrictionInputHint =>
      'Escribe los alimentos que no puedes comer';

  @override
  String get foodVegetarian => 'Vegetariano';

  @override
  String get foodVegan => 'Vegano';

  @override
  String get foodHalal => 'Halal';

  @override
  String get foodKosher => 'Kosher';

  @override
  String get foodGluten => 'Intolerancia al gluten';

  @override
  String get foodPeanut => 'Alergia al maní';

  @override
  String get foodDairy => 'Alergia a lácteos';

  @override
  String get foodSeafood => 'Alergia a mariscos';

  @override
  String get foodNone => 'Ninguno';

  @override
  String get foodBreakfastTitle => 'Desayuno';

  @override
  String get foodSkipBreakfast => 'Normalmente no desayuno';

  @override
  String get foodSkipBreakfastSub => 'Se usa para estimar el número de comidas';

  @override
  String get flightArrival => 'Llegada';

  @override
  String get flightDeparture => 'Salida';

  @override
  String flightInfoTitle(String dir) {
    return 'Información del vuelo de $dir';
  }

  @override
  String flightDateLabel(String dir) {
    return 'Fecha de $dir *';
  }

  @override
  String flightAirportLabel(String dir) {
    return 'Aeropuerto de $dir';
  }

  @override
  String flightTimeLabel(String dir) {
    return 'Hora prevista de $dir';
  }

  @override
  String get flightPickDate => 'Selecciona una fecha';

  @override
  String get flightNumber => 'Número de vuelo';

  @override
  String get flightNumberHint => 'ej. KE123, OZ456';

  @override
  String get flightAutoSearch => 'Buscar vuelo automáticamente';

  @override
  String get flightNotFound =>
      'No se encontró información del vuelo. Ingrésala manualmente.';

  @override
  String flightStatus(String value) {
    return 'Estado: $value';
  }

  @override
  String get flightAutoFillHint => 'Se completa al buscar por número de vuelo';

  @override
  String get volQuestion => '¿Puedes ayudar con el programa?';

  @override
  String get volHelp => 'Selecciona todo lo que corresponda. (Opcional)';

  @override
  String get volOtherLabel => 'Otras formas en que puedes ayudar (opcional)';

  @override
  String get volOtherHint =>
      'Escribe talentos o recursos que no estén en la lista';

  @override
  String get volPiano => 'Piano';

  @override
  String get volGuitar => 'Guitarra';

  @override
  String get volBass => 'Bajo';

  @override
  String get volDrums => 'Batería';

  @override
  String get volViolin => 'Violín';

  @override
  String get volWorshipLead => 'Dirección de alabanza';

  @override
  String get volVocals => 'Voz';

  @override
  String get volTranslation => 'Interpretación/Traducción';

  @override
  String get volPhotography => 'Foto/Video';

  @override
  String get volSound => 'Sonido';

  @override
  String get volDesign => 'Diseño';

  @override
  String get volIt => 'TI/Tecnología';

  @override
  String get volChildcare => 'Cuidado de niños';

  @override
  String get volCooking => 'Cocina';

  @override
  String get volDriving => 'Conducción';

  @override
  String get volMedical => 'Médico/Primeros auxilios';

  @override
  String get summaryTitle => 'Resumen del registro';

  @override
  String get summarySectionProgram => 'Programa';

  @override
  String get summaryName => 'Nombre';

  @override
  String get summaryLocation => 'Lugar';

  @override
  String get summaryPeriod => 'Fechas';

  @override
  String get summaryCountry => 'País';

  @override
  String get summaryBranch => 'Capítulo';

  @override
  String get summaryRealName => 'Nombre real';

  @override
  String get summaryBibleName => 'Nombre bíblico';

  @override
  String get summaryAge => 'Edad';

  @override
  String get summaryFlightNo => 'Vuelo';

  @override
  String get summaryArrAirport => 'Aeropuerto de llegada';

  @override
  String get summaryArrTime => 'Llegada prevista';

  @override
  String get summaryDepAirport => 'Aeropuerto de salida';

  @override
  String get summaryDepTime => 'Salida prevista';

  @override
  String get summarySectionFood => 'Necesidades alimentarias';

  @override
  String get summarySectionOptions => 'Programas seleccionados';

  @override
  String get summarySectionRoommate => 'Preferencia de compañero';

  @override
  String get summaryTotalCost => 'Pago total';

  @override
  String get summaryNoPaidOptions => 'No hay opciones de pago seleccionadas';

  @override
  String get summaryViewImmigration => 'Ver tarjeta de inmigración';

  @override
  String get summarySubmit => 'Enviar';

  @override
  String get summaryEditBtn => 'Editar';

  @override
  String get summarySubmitConfirm =>
      '¿Deseas enviar tu registro?\nLa edición puede estar restringida después del envío.';

  @override
  String get summarySubmitDone => 'Enviado';

  @override
  String get summarySubmitDoneMsg =>
      'Tu registro se envió correctamente.\nUn organizador te contactará después de revisarlo.';

  @override
  String summarySubmitFailed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get commonNoName => 'Sin nombre';

  @override
  String unitPeople(int count) {
    return '$count personas';
  }

  @override
  String unitCases(int count) {
    return '$count';
  }

  @override
  String get dashTitle => 'Panel';

  @override
  String get dashExport => 'Exportar';

  @override
  String get dashExportExcel => 'Exportar a Excel';

  @override
  String get dashExportCsv => 'Exportar a CSV';

  @override
  String get dashEditSettings => 'Editar configuración del programa';

  @override
  String get dashSetupSubtitle =>
      'Define alojamiento y grupos de estudio (paso previo a la asignación)';

  @override
  String get dashPendingPayments => 'Pagos por confirmar';

  @override
  String get dashViewAll => 'Ver todo';

  @override
  String get dashNoPendingPayments => 'No hay pagos por confirmar';

  @override
  String get dashAttendeeList => 'Participantes';

  @override
  String get dashNoAttendees => 'Aún no hay participantes registrados';

  @override
  String get dashSendNotice => 'Enviar anuncio al grupo';

  @override
  String get dashNoStats => 'Sin estadísticas';

  @override
  String get dashStatTotal => 'Total registrados';

  @override
  String get dashStatSubmitted => 'Completados';

  @override
  String get dashStatFoodRestriction => 'Restricciones alimentarias';

  @override
  String get dashStatPendingPayment => 'Pago pendiente';

  @override
  String get dashStatArrival => 'Vuelos de llegada';

  @override
  String get dashStatConfirmedPayment => 'Pago confirmado';

  @override
  String get dashPaymentPending => 'Esperando confirmación';

  @override
  String get dashStatusDone => 'Hecho';

  @override
  String get dashStatusInProgress => 'En curso';

  @override
  String get pcTitle => 'Programa creado';

  @override
  String get pcHeading => '¡Tu programa ha sido creado!';

  @override
  String get pcShareUuid => 'Comparte el UUID de abajo con los participantes';

  @override
  String get pcCopy => 'Copiar';

  @override
  String get pcCopied => 'UUID copiado';

  @override
  String get pcInfo =>
      'Los participantes pueden registrarse ingresando este UUID en la app.';

  @override
  String get pcGoDashboard => 'Ir al panel';

  @override
  String get pcGoHome => 'Inicio';

  @override
  String get cpProgramType => 'Tipo de programa';

  @override
  String get cpTypeLocal => 'Retiro local';

  @override
  String get cpTypeInternational => 'Retiro internacional';

  @override
  String get cpLocalNote =>
      'Retiro local: las secciones de vuelo y tour se desactivan automáticamente';

  @override
  String get cpBasicInfo => 'Información básica';

  @override
  String get cpNameLabel => 'Nombre del programa *';

  @override
  String get cpNameHint => 'ej. Retiro de Verano 2025';

  @override
  String get cpNameRequired => 'Ingresa un nombre de programa';

  @override
  String get cpLocationLabel => 'Lugar *';

  @override
  String get cpLocationHint => 'ej. Centro de Convenciones de Jeju';

  @override
  String get cpLocationRequired => 'Ingresa un lugar';

  @override
  String get cpStartDate => 'Seleccionar fecha de inicio';

  @override
  String get cpEndDate => 'Seleccionar fecha de fin';

  @override
  String get cpPeriod => 'Seleccionar período (inicio ~ fin)';

  @override
  String get cpHostCountry => 'País anfitrión';

  @override
  String get cpHostCountryHint => 'Busca y selecciona un país';

  @override
  String get cpHostCountryHelp =>
      'Los participantes que viven en el país anfitrión omiten el ingreso del vuelo';

  @override
  String get cpImmigrationInfo => 'Información de inmigración';

  @override
  String get cpImmigrationDesc =>
      'Información que los participantes pueden mostrar al oficial de inmigración al llegar (opcional)';

  @override
  String get cpNearestAirport => 'Aeropuerto más cercano';

  @override
  String get cpAirportHint => 'ej. Aeropuerto Intl. de Incheon (ICN)';

  @override
  String get cpContacts => 'Contactos en el lugar (2)';

  @override
  String get cpName1 => 'Nombre 1';

  @override
  String get cpName1Hint => 'Juan Pérez';

  @override
  String get cpPhone1 => 'Teléfono 1';

  @override
  String get cpName2 => 'Nombre 2';

  @override
  String get cpName2Hint => 'María López';

  @override
  String get cpPhone2 => 'Teléfono 2';

  @override
  String get cpSectionsTitle => 'Activar secciones de registro';

  @override
  String get cpSectionsDesc => 'Elige qué elementos verán los participantes';

  @override
  String get cpSecVolunteer =>
      'Recursos de ayuda del programa (instrumentos, traducción, etc.)';

  @override
  String get cpSpecialOptions => 'Programas especiales / opciones de tour';

  @override
  String get cpOptionsDesc =>
      'Define un costo por opción para que los participantes puedan elegir';

  @override
  String cpOptionCost(String value) {
    return 'Costo: $value';
  }

  @override
  String get cpOptionName => 'Nombre de la opción';

  @override
  String get cpOptionNameHint => 'Tour Jeju Ruta A';

  @override
  String get cpOptionCostLabel => 'Costo';

  @override
  String get cpCreateButton => 'Crear programa (emitir UUID)';

  @override
  String get cpDupTitle => 'El programa ya existe';

  @override
  String get cpDupBody =>
      'Ya existe un programa con el mismo nombre y fecha de inicio.\n¿Ir a la pantalla de UUID del programa existente?';

  @override
  String get cpDupGoExisting => 'Ir al programa existente';

  @override
  String cpCreateFailed(String error) {
    return 'Error al crear el programa: $error';
  }

  @override
  String get epSaved => 'Configuración guardada';

  @override
  String get epNotFound => 'Programa no encontrado';

  @override
  String get epTourLocked =>
      'El retiro ya comenzó, por lo que no se pueden editar las opciones de tour';

  @override
  String epOptionContact(String value) {
    return 'Responsable: $value';
  }

  @override
  String get epAddOption => 'Añadir opción';

  @override
  String get epEditOption => 'Editar opción';

  @override
  String get epSaveChanges => 'Guardar cambios';

  @override
  String get epOptionNameReq => 'Nombre de la opción *';

  @override
  String get epOptionCostNum => 'Costo (número)';

  @override
  String get epOptionContactName => 'Nombre del responsable';

  @override
  String get epOptionDesc => 'Descripción (opcional)';

  @override
  String get epPickDate => 'Seleccionar fecha';

  @override
  String epPhotos(int count) {
    return 'Fotos ($count/6)';
  }

  @override
  String get epPhotoUrlTitle => 'Añadir URL de foto';

  @override
  String get epPhotoUrlLabel => 'URL de imagen';

  @override
  String get epCapacity => 'Cupo';

  @override
  String get epSignupDeadline => 'Cierre de inscripción';

  @override
  String get epBrochureUrl => 'Enlace del folleto';

  @override
  String get epVideoUrl => 'Enlace del video';

  @override
  String get tourCapacityLabel => 'Plazas disponibles';

  @override
  String tourRemaining(int remaining, int capacity) {
    return '$remaining / $capacity';
  }

  @override
  String get tourFull => 'Completo';

  @override
  String get tourClosed => 'Cerrado';

  @override
  String tourDeadline(String date) {
    return 'Cierre: $date';
  }

  @override
  String get linkCopied => 'Enlace copiado';

  @override
  String get blTitle => 'Registrarse como líder';

  @override
  String get blInfo =>
      'Registrarte como líder te permite crear programas de retiro y gestionar participantes.';

  @override
  String get blLoginAccount => 'Cuenta con la que iniciaste sesión';

  @override
  String get blLeaderName => 'Nombre del líder *';

  @override
  String get blLeaderNameHint => 'Nombre que verán los participantes';

  @override
  String get blRegisterButton => 'Registrarme y crear un evento';

  @override
  String blLeaderRegFailed(String error) {
    return 'Error al registrar el líder: $error';
  }

  @override
  String get sosTitle => 'SOS de emergencia';

  @override
  String get sosHealth => '🚑 Emergencia médica/de salud';

  @override
  String get sosSafety => '🆘 Amenaza a la seguridad personal';

  @override
  String get sosLost => '🗺️ Estoy perdido';

  @override
  String get sosGpsOff => 'El GPS está apagado. Actívalo en la configuración.';

  @override
  String get sosPermDenied =>
      'Permiso de ubicación denegado. Enviando SOS sin ubicación.';

  @override
  String sosLocationError(String error) {
    return 'No se pudo obtener la ubicación: $error';
  }

  @override
  String get sosSentTitle => 'SOS enviado';

  @override
  String get sosSentMsg =>
      'Se ha enviado una alerta de emergencia a los organizadores.\nEspera un momento.';

  @override
  String sosSendFailed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get sosBanner =>
      'Se envía una alerta a los organizadores de inmediato.\nÚsalo solo en una emergencia.';

  @override
  String get sosSelectType => 'Selecciona el tipo de situación';

  @override
  String get sosMessageLabel => 'Mensaje adicional (opcional)';

  @override
  String get sosMessageHint => 'Describe brevemente tu situación actual';

  @override
  String sosGpsConfirmed(String value) {
    return 'Ubicación GPS confirmada $value';
  }

  @override
  String get sosGpsChecking => 'Verificando ubicación GPS...';

  @override
  String get sosSending => 'Enviando...';

  @override
  String get sosSend => 'Enviar SOS';

  @override
  String get sosFabConfirm =>
      '¿Enviar una alerta de emergencia a los organizadores?';

  @override
  String schLoadFailed(String error) {
    return 'Error al cargar el horario: $error';
  }

  @override
  String get schAddTitle => 'Añadir evento';

  @override
  String get schTitleLabel => 'Título *';

  @override
  String get schTitleHint => 'Culto de apertura';

  @override
  String get schDescLabel => 'Descripción (opcional)';

  @override
  String get schPickTime => 'Seleccionar hora';

  @override
  String get schTimezone => 'Zona horaria';

  @override
  String get schTzAuto =>
      'Se establece automáticamente según la zona horaria de tu dispositivo';

  @override
  String get schTzReset => 'Restablecer a la zona horaria del dispositivo';

  @override
  String get schAllRequired => 'Ingresa título, fecha y hora';

  @override
  String schAddFailed(String error) {
    return 'Error al añadir: $error';
  }

  @override
  String get schTzChangeTitle => 'Cambiar zona horaria';

  @override
  String get schTzUseDevice => 'Usar la zona horaria de mi dispositivo';

  @override
  String get schTzExamples => 'ej. Asia/Seoul, America/New_York, Europe/London';

  @override
  String schTzChangeFailed(String error) {
    return 'Error al cambiar la zona horaria: $error';
  }

  @override
  String get schDeleteTitle => 'Eliminar evento';

  @override
  String get schDeleteConfirm => '¿Eliminar este evento?';

  @override
  String schDeleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get schEmpty => 'No hay eventos programados';

  @override
  String get immTitle => 'Tarjeta de inmigración';

  @override
  String get immFullscreenTooltip => 'Pantalla completa (mostrar al oficial)';

  @override
  String get immNotFound => 'No se encontró información del programa.';

  @override
  String get immBanner =>
      'Toca el botón de pantalla completa arriba a la derecha para mostrarla al oficial.';

  @override
  String get immCardPurpose => 'PURPOSE OF VISIT / Motivo de la visita';

  @override
  String get immCardConference =>
      'Religious Conference / Conferencia religiosa';

  @override
  String get immCardVenue => 'VENUE / Lugar';

  @override
  String get immCardDate => 'DATE / Fecha';

  @override
  String get immCardAirport => 'NEAREST AIRPORT / Aeropuerto más cercano';

  @override
  String get immCardContact => 'ON-SITE CONTACT / Contacto en el lugar';

  @override
  String get immCardFooter =>
      'I am attending the above religious conference as a participant.\nAsisto a la conferencia religiosa anterior como participante.';

  @override
  String get immExitHint =>
      'Tap anywhere to exit fullscreen\nToca en cualquier lugar para salir de pantalla completa';

  @override
  String setupRoomsMade(int count) {
    return 'Habitaciones creadas · $count';
  }

  @override
  String get setupRoomsEmpty =>
      'Aún no hay habitaciones.\nUsa el botón de abajo a la derecha para añadirlas en lote.';

  @override
  String get setupBulkAddRooms => 'Añadir habitaciones en lote';

  @override
  String setupRoomsAdded(int count) {
    return 'Se añadieron $count habitaciones';
  }

  @override
  String get setupReconcileTitle => 'Registrados vs capacidad';

  @override
  String get setupMale => 'Hombres';

  @override
  String get setupFemale => 'Mujeres';

  @override
  String setupMixedSeats(int count) {
    return 'Habitaciones de pareja/familia: $count plazas (asignadas por familia)';
  }

  @override
  String setupRegVsSeats(int regs, int seats) {
    return 'Registrados $regs · Capacidad $seats';
  }

  @override
  String setupSeatShortage(int count) {
    return 'Faltan $count plazas';
  }

  @override
  String setupRoomCapacity(int count) {
    return '$count pers.';
  }

  @override
  String get setupCouple => 'Habitación de pareja';

  @override
  String get setupCoupleSub => '2 pers. · mixta';

  @override
  String get setupFamily => 'Habitación familiar';

  @override
  String get setupFamilySub => '3–4 pers. · mixta';

  @override
  String get setupDorm => 'Habitación grupal';

  @override
  String get setupDormSub => '5+ · un solo género';

  @override
  String get setupMixed => 'Familia (mixta)';

  @override
  String get setupRoomType => 'Tipo de habitación';

  @override
  String get setupNameRule => 'Patrón de nombre';

  @override
  String get setupNameRuleHint => 'ej. 3P 3##';

  @override
  String get setupStartNum => 'Inicio#';

  @override
  String get setupCount => 'Cantidad';

  @override
  String get setupCapacity => 'Capacidad';

  @override
  String get setupFloor => 'Piso (opcional)';

  @override
  String get setupMixedNotAllowed => 'Mixta no permitida';

  @override
  String get setupFamilyAuto => 'Unidad familiar (mixta) — automático';

  @override
  String get setupBulkValidation =>
      'Revisa el patrón de nombre, la cantidad y la capacidad';

  @override
  String setupGroupsMade(int count) {
    return 'Grupos creados · $count';
  }

  @override
  String get setupGroupsEmpty =>
      'Aún no hay grupos.\nUsa el botón de abajo a la derecha para crearlos.';

  @override
  String get setupMakeGroups => 'Crear grupos';

  @override
  String get setupMakeGroupsPrompt =>
      '¿Cuántos grupos? (Grupo 1, Grupo 2 … generados automáticamente)';

  @override
  String get setupGroupCount => 'Número de grupos';

  @override
  String get setupGroupCountSuffix => '';

  @override
  String get setupMake => 'Crear';

  @override
  String setupGroupsCreated(int count) {
    return 'Se crearon $count grupos';
  }

  @override
  String get setupMakeGroupsFirst => 'Primero crea los grupos';

  @override
  String setupEvenPerGroup(int count) {
    return 'Unos $count por grupo, equilibrado';
  }

  @override
  String setupUnevenPerGroup(int remCount, int bigger, int base) {
    return '$remCount grupos tienen $bigger, el resto $base';
  }

  @override
  String get setupGroupSummary => 'Resumen de grupos';

  @override
  String setupRegAndGroups(int total, int groups) {
    return '$total registrados · $groups grupos';
  }

  @override
  String setupBalancePreview(String preview) {
    return 'Con equilibrio de edad/género — $preview';
  }

  @override
  String setupLeaderless(int count) {
    return '$count sin líder';
  }

  @override
  String get setupNoPassageLocation => 'Sin pasaje/lugar';

  @override
  String get setupNoLeader => 'Sin líder asignado';

  @override
  String get setupEditGroupMenu => 'Editar líder/pasaje/lugar';

  @override
  String setupEditGroupTitle(String name) {
    return 'Editar $name';
  }

  @override
  String get setupGroupName => 'Nombre del grupo';

  @override
  String get setupLeaderName => 'Nombre del líder (pastor)';

  @override
  String get setupLeaderPhone => 'Teléfono del líder';

  @override
  String get setupPassage => 'Pasaje (ej. Juan 10)';

  @override
  String get setupLocation => 'Lugar de reunión';

  @override
  String get expColNo => 'N.º';

  @override
  String get expArrFlight => 'Vuelo de llegada';

  @override
  String get expArrTime => 'Fecha/hora de llegada';

  @override
  String get expDepFlight => 'Vuelo de salida';

  @override
  String get expDepTime => 'Fecha/hora de salida';

  @override
  String get expOptions => 'Opciones seleccionadas';

  @override
  String get expTotalCost => 'Costo total';

  @override
  String get expPaymentStatus => 'Estado del pago';

  @override
  String get expSubmittedCol => 'Registro completo';

  @override
  String get expUnregistered => 'No registrado';

  @override
  String get expIncomplete => 'Incompleto';

  @override
  String get expRoster => 'Lista de participantes';

  @override
  String get regStepCompanion => 'Acompañantes';

  @override
  String get regStepBuddy => 'Solicitudes de compañía';

  @override
  String get buddyTitle => 'Personas con quienes quieres estar';

  @override
  String get buddyDesc =>
      'Cuando eliges a alguien, se envía una solicitud. Se confirma solo cuando la acepta.';

  @override
  String get buddyRoommateSection => 'Solicitudes de compañero de cuarto';

  @override
  String get buddyGroupSection => 'Solicitudes de grupo de estudio';

  @override
  String get buddySearchHint => 'Busca por nombre o nombre bíblico…';

  @override
  String get buddySendRoommate => 'Pedir como compañero de cuarto';

  @override
  String get buddySendGroup => 'Pedir el mismo grupo';

  @override
  String get buddySentSection => 'Solicitudes que enviaste';

  @override
  String get buddyReceivedSection => 'Solicitudes que recibiste';

  @override
  String get buddyStatusPending => 'Pendiente';

  @override
  String get buddyStatusAccepted => 'Aceptada';

  @override
  String get buddyStatusDeclined => 'Rechazada';

  @override
  String get buddyAccept => 'Aceptar';

  @override
  String get buddyDecline => 'Rechazar';

  @override
  String get buddyKindRoommate => 'Compañero de cuarto';

  @override
  String get buddyKindGroup => 'Grupo';

  @override
  String get buddyReqSent => 'Solicitud enviada';

  @override
  String get buddyRoommateSameGenderNote =>
      'Las solicitudes de compañero de cuarto solo pueden enviarse al mismo género o a la familia que viaja contigo.';

  @override
  String get buddyReceivedEmpty => 'No hay solicitudes recibidas';

  @override
  String get buddyNoCandidates => 'Aún no hay otros participantes para elegir';

  @override
  String buddyRequestLine(String kind) {
    return 'Solicitud de $kind';
  }

  @override
  String get companionTitle => 'Acompañantes (pareja/familia)';

  @override
  String get companionDesc =>
      'Si vienes con tu cónyuge o familia, agrégalos aquí. Cada uno cuenta para el aforo y el transporte.';

  @override
  String get companionAdd => 'Agregar acompañante';

  @override
  String get companionEmpty => 'Déjalo vacío si asistes solo.';

  @override
  String get companionLanguage => 'Idioma';

  @override
  String get companionSameFlight => 'Mismo vuelo que yo';

  @override
  String get companionArrivalFlightNo => 'Vuelo de llegada del acompañante';

  @override
  String get companionDepartureFlightNo => 'Vuelo de salida del acompañante';

  @override
  String get companionNeedsPickup => 'Necesita transporte';

  @override
  String companionCount(int count) {
    return '$count acompañante(s)';
  }

  @override
  String get companionAddTitle => 'Agregar acompañante';

  @override
  String get companionEditTitle => 'Editar acompañante';

  @override
  String get asnTitle => 'Asignación';

  @override
  String get asnAutoAssign => 'Asignar automáticamente';

  @override
  String asnAutoRoomsDone(int count) {
    return 'Alojamiento asignado — $count ubicados';
  }

  @override
  String asnAutoGroupsDone(int count) {
    return 'Grupos asignados — $count ubicados';
  }

  @override
  String asnUnplaced(int count) {
    return '$count no se pudieron ubicar';
  }

  @override
  String get asnUnassigned => 'Sin asignar';

  @override
  String asnUnassignedCount(int count) {
    return '$count sin asignar';
  }

  @override
  String get asnPickRoom => 'Elegir habitación';

  @override
  String get asnPickGroup => 'Elegir grupo';

  @override
  String get asnNoRooms => 'Primero crea habitaciones en Preparación';

  @override
  String get asnNoGroups => 'Primero crea grupos en Preparación';

  @override
  String get asnAllAssigned => 'Todos están asignados';

  @override
  String get dashAssignSubtitle => 'Asigna alojamiento y grupos de estudio';

  @override
  String get dashDispatchSubtitle =>
      'Lista de conductores y asignación automática';

  @override
  String get dspTitle => 'Transporte';

  @override
  String get dspTabArrival => 'Recogida (llegada)';

  @override
  String get dspTabDeparture => 'Salida';

  @override
  String get dspAddVan => 'Agregar furgoneta';

  @override
  String get dspAutoDispatch => 'Asignación automática';

  @override
  String get dspNoRuns => 'Registra primero una furgoneta (conductor y cupo)';

  @override
  String dspAutoDone(int assigned, int unassigned) {
    return '$assigned asignados · $unassigned sin asignar';
  }

  @override
  String dspUnassignedCount(int count) {
    return 'Sin asignar $count';
  }

  @override
  String get dspAllAssigned => 'Todos asignados';

  @override
  String get dspPickVan => 'Elegir furgoneta';

  @override
  String get dspDriverUnset => 'Sin conductor';

  @override
  String get dspNewVan => 'Nueva furgoneta';

  @override
  String get dspEditVan => 'Editar furgoneta';

  @override
  String get dspAirport => 'Aeropuerto';

  @override
  String get dspVehicle => 'Vehículo';

  @override
  String get dspDriverName => 'Nombre del conductor';

  @override
  String get dspDriverPhone => 'Teléfono del conductor';

  @override
  String get dspCapacityLabel => 'Cupo';

  @override
  String get dspMeetPoint => 'Punto de encuentro';

  @override
  String get dspDeleteVan => 'Eliminar furgoneta';

  @override
  String get mtrTitle => 'Mi transporte';

  @override
  String get mtrArrival => 'Recogida (llegada)';

  @override
  String get mtrDeparture => 'Salida';

  @override
  String mtrArrivalRoute(String airport) {
    return '$airport → Sede del retiro';
  }

  @override
  String mtrDepartureRoute(String airport) {
    return 'Sede del retiro → $airport';
  }

  @override
  String get mtrPending => 'El transporte se organizará pronto';

  @override
  String get mtrAssigned => 'Asignado';

  @override
  String get mtrPendingBadge => 'Pendiente';

  @override
  String get mtrVehicle => 'Vehículo';

  @override
  String get mtrDriver => 'Conductor';

  @override
  String get mtrCoPassengers => 'Con';

  @override
  String get mtrMeetPoint => 'Punto de encuentro';

  @override
  String get mtrSelfDrive => 'Voy por mi cuenta';

  @override
  String get mtrSelfDriveDesc => 'Desactiva si no necesitas recogida';

  @override
  String get mtrHostCountryTitle =>
      'No te corresponde recogida en el aeropuerto';

  @override
  String get mtrHostCountryDesc =>
      'Asistes desde el país anfitrión, así que no figuras en la lista de recogida del aeropuerto. ¿Llegas en avión? Agrega tu vuelo en la inscripción y te incluiremos.';

  @override
  String get rdyTitle => 'Estado de preparación';

  @override
  String get rdySubtitle => 'Qué está bloqueado y a quién contactar';

  @override
  String get rdySectionItems => 'Elementos de preparación';

  @override
  String get rdySectionCohorts => 'Asistentes nacionales y del extranjero';

  @override
  String get rdySectionBlocked => 'Personas a contactar';

  @override
  String get rdyLodging => 'Alojamiento';

  @override
  String get rdyTransport => 'Transporte de recogida';

  @override
  String get rdyFlights => 'Vuelos sin registrar';

  @override
  String get rdyMeals => 'Comidas';

  @override
  String get rdyPayment => 'Cuotas';

  @override
  String get rdyRoles => 'Cargos en la iglesia';

  @override
  String get rdyDomestic => 'Nacional';

  @override
  String get rdyOverseas => 'Del extranjero';

  @override
  String get rdySkipped => 'Omitido';

  @override
  String get rdyUnspecified => 'Sin especificar';

  @override
  String get rdyStuckPersonal => 'Información personal';

  @override
  String get rdyStuckMeals => 'Comidas';

  @override
  String get rdyStuckFlight => 'Vuelo';

  @override
  String get rdyStuckLodging => 'Alojamiento';

  @override
  String get rdyStuckPayment => 'Cuotas';

  @override
  String get rdyStatusOk => 'Bien';

  @override
  String get rdyStatusWarn => 'Atención';

  @override
  String get rdyStatusStop => 'Insuficiente';

  @override
  String get rdyStatusIdle => 'Sin configurar';

  @override
  String get rdyNoBlocked => 'Todos van al día';

  @override
  String get rdyRolesUnreliable => 'Más de la mitad no tiene cargo registrado';

  @override
  String get rdyOpenCard => 'Ver estado de preparación';

  @override
  String get rdyOpenCardSub => 'Bloqueos y contactos de un vistazo';

  @override
  String get privacyTitle => 'Cómo se usa su información';

  @override
  String get privacySummary =>
      'Lo que registre aquí se usa únicamente para organizar el retiro.';

  @override
  String get privacyWhatTitle => 'Qué recogemos';

  @override
  String get privacyWhat =>
      'Nombre, nombre bíblico, sexo, edad, país de residencia y capítulo; datos de vuelo; restricciones alimentarias; condiciones de salud; preferencia de compañero de cuarto; estado del pago. Si usa SOS, también se envía su ubicación en ese momento.';

  @override
  String get privacyWhyTitle => 'Para qué';

  @override
  String get privacyWhy =>
      'Para asignar habitaciones y grupos, organizar la recogida en el aeropuerto, preparar las comidas y atender emergencias. Nada más.';

  @override
  String get privacyWhoTitle => 'Quién puede verlo';

  @override
  String get privacyWho =>
      'Los organizadores del retiro. Los demás participantes solo ven lo que compartes por QR: tu versículo, tus motivos de oración y los contactos que actives. La información de salud nunca se comparte con participantes; no aparece en las listas, un organizador la abre por persona cuando hace falta y ese acceso queda registrado.';

  @override
  String get privacyWhereTitle => 'Dónde se guarda';

  @override
  String get privacyWhere =>
      'Los datos se guardan en una base de datos en la nube ubicada en Estados Unidos. Esto significa que salen de su país de residencia.';

  @override
  String get privacyKeepTitle => 'Por cuánto tiempo';

  @override
  String get privacyKeep =>
      'Se conservan hasta un año después del retiro y luego se eliminan.';

  @override
  String get privacyRightsTitle => 'Sus opciones';

  @override
  String get privacyRights =>
      'Puedes modificar lo que registraste en cualquier momento. En el compartir por QR puedes desactivar cada dato, cortar a quien haya guardado tu tarjeta o crear un QR nuevo para que los códigos anteriores dejen de funcionar. Para eliminar tus datos, pídelo a un organizador.';

  @override
  String get privacyAgree => 'He leído esta información';

  @override
  String get privacyMore => 'Ver más';

  @override
  String get privacyLess => 'Ver menos';

  @override
  String get regStepFee => 'Cuota';

  @override
  String get feePrompt => 'Elige un nivel de cuota.';

  @override
  String get feeTierBasic => 'Estándar';

  @override
  String get feeTierPremium => 'Premium';

  @override
  String get feeNotSet => 'Aún no se ha fijado la cuota.';

  @override
  String get discountTitle => 'Solicitud de descuento';

  @override
  String get discountPrompt =>
      'Si alguna de estas opciones aplica, selecciónala.';

  @override
  String get discountNone => 'Sin solicitud de descuento';

  @override
  String get discountReasonLabel => 'Nota adicional (opcional)';

  @override
  String get discountReasonHint => 'Algo que los organizadores deban saber';

  @override
  String get discountStatusPending =>
      'Esperando la revisión de los organizadores.';

  @override
  String discountStatusApproved(String amount) {
    return 'Aprobado — $amount de descuento';
  }

  @override
  String get discountStatusRejected => 'No aprobado.';

  @override
  String discountAdminNote(String note) {
    return 'Nota del organizador: $note';
  }

  @override
  String get cohortSection => 'Equipos de estudio bíblico';

  @override
  String get cohortHint =>
      'Los equipos se dividen primero por idioma y luego por edad. Adulto 20+ · Junior 19 o menos.';

  @override
  String get cohortMinSize => 'Tamaño mínimo del equipo';

  @override
  String get cohortKeep => 'Dejar como está';

  @override
  String get cohortKeepSub =>
      'Si ningún equipo encaja, quedan sin asignar para que usted decida';

  @override
  String get cohortAbsorb => 'Subir al equipo Adulto del mismo idioma';

  @override
  String get cohortAbsorbSub => 'Prioriza el idioma que comparten';

  @override
  String get cohortMerge => 'Unir con la misma franja de edad de otro idioma';

  @override
  String get cohortMergeSub => 'Prioriza estar con gente de su edad';

  @override
  String get studyLangTitle => '¿En qué idioma quiere estudiar la Biblia?';

  @override
  String get studyLangBody =>
      'Los equipos de estudio bíblico se forman por este idioma.';

  @override
  String get studyLangNote =>
      'Puede cambiarlo más adelante desde su inscripción.';

  @override
  String get regStepStudyLang => 'Estudio bíblico';

  @override
  String get discountNoOptions =>
      'Esta conferencia no admite solicitudes de descuento.';

  @override
  String discountDomesticOnly(String country) {
    return 'Solo pueden solicitar descuento quienes asisten desde $country.';
  }

  @override
  String get cpFeeSection => 'Cuota';

  @override
  String get cpFeeBasic => 'Cuota estándar';

  @override
  String get cpFeePremium => 'Cuota premium';

  @override
  String get cpFeeBasicDesc => 'Qué incluye la cuota estándar';

  @override
  String get cpFeePremiumDesc => 'Qué incluye la cuota premium';

  @override
  String get cpFeeHint => 'Déjalo vacío si no ofreces ese nivel.';

  @override
  String get cpFeeInvalid => 'Introduce un número igual o mayor que 0.';

  @override
  String get cpDiscountSection => 'Opciones de descuento';

  @override
  String get cpDiscountHint =>
      'Motivos que los asistentes pueden elegir al pedir un descuento; por ejemplo, «Asisto solo un día».';

  @override
  String get cpDiscountLabel => 'Texto que verán los asistentes';

  @override
  String get cpDiscountAmount => 'Importe del descuento (opcional)';

  @override
  String get cpDiscountAmountHint =>
      'Déjalo vacío para decidirlo caso por caso.';

  @override
  String get cpDiscountAdd => 'Añadir opción de descuento';

  @override
  String get cpDiscountRemove => 'Eliminar';

  @override
  String get cpDiscountEmpty => 'Aún no hay opciones de descuento.';

  @override
  String get adDiscountTitle => 'Solicitudes de descuento';

  @override
  String get adDiscountNone => 'No hay solicitudes de descuento.';

  @override
  String get adDiscountApprove => 'Aprobar';

  @override
  String get adDiscountReject => 'Rechazar';

  @override
  String get adDiscountAmount => 'Importe del descuento';

  @override
  String get adDiscountNote => 'Nota (opcional)';

  @override
  String get adDiscountAmountReq => 'Se necesita un importe para aprobar.';

  @override
  String get adDiscountSaved => 'Guardado.';

  @override
  String get adDiscountPending => 'Pendiente';

  @override
  String get adDiscountApproved => 'Aprobado';

  @override
  String get adDiscountRejected => 'Rechazado';

  @override
  String get myProgramsTitle => 'Mis conferencias';

  @override
  String get myProgramsEmpty =>
      'Aún no has creado ninguna conferencia.\nUsa el botón de abajo para crear una.';

  @override
  String get myProgramsEdit => 'Editar';

  @override
  String myProgramsRegistered(int count) {
    return '$count inscritos';
  }

  @override
  String get cpCurrency => 'Moneda';

  @override
  String get cpCurrencyHint =>
      'Todos los asistentes de esta conferencia verán los importes en esta moneda. No se aplica conversión de tipo de cambio.';

  @override
  String cpCurrencyFixed(String code) {
    return 'Las conferencias internacionales se cobran en $code. Los asistentes vienen de muchos países, así que la moneda es la misma para todos.';
  }

  @override
  String get flightNotBookedYet => 'Todavía no he comprado mi vuelo';

  @override
  String get flightNotBookedYetHint =>
      'Indica solo la fecha prevista. Puedes añadir el vuelo más adelante.';

  @override
  String get flightEstimatedNotice =>
      'Se guarda como estimación, no como vuelo confirmado. Vuelve a añadir el vuelo cuando lo compres.';

  @override
  String get expFlightEstimated => '(estimación — sin comprar)';

  @override
  String get buddyFamilyTitle => '¿Vienen juntos?';

  @override
  String get buddyFamilyBody =>
      'Esta persona es de otro género. Las habitaciones son del mismo género por defecto; solo pueden compartir si son familia que viaja junta (cónyuge, padre e hijo, etc.). La otra persona también debe aceptar.';

  @override
  String get buddyFamilyConfirm => 'Sí, somos familia';

  @override
  String get myProgramsDelete => 'Eliminar';

  @override
  String get myProgramsDeleteTitle => '¿Eliminar esta conferencia?';

  @override
  String myProgramsDeleteBody(String name) {
    return '\"$name\" dejará de mostrarse a todos. Las inscripciones y asignaciones se conservan; pide ayuda a un administrador si necesitas recuperarla.';
  }

  @override
  String myProgramsDeleteHasRegistrations(int count) {
    return 'Ya se han inscrito $count personas. Escribe el nombre de la conferencia para confirmar.';
  }

  @override
  String get myProgramsDeleteTypeName => 'Nombre de la conferencia';

  @override
  String get myProgramsDeleted => 'Eliminada.';

  @override
  String get mealsTitle => 'Restricciones alimentarias';

  @override
  String get mealsSubtitle => 'Quién no puede comer qué — para la cocina';

  @override
  String get mealsEmpty => 'Nadie ha indicado una restricción alimentaria.';

  @override
  String get mealsRestriction => 'No puede comer · notas';

  @override
  String get mealsSkipsBreakfast => 'no desayuna';

  @override
  String mealsSummary(int restricted, int total) {
    return '$restricted de $total participantes';
  }

  @override
  String mealsPdfSummary(int restricted, int total) {
    return '$restricted de $total participantes inscritos indicaron una restricción alimentaria.';
  }

  @override
  String get mealsPdfNote =>
      'Recopilado de lo que cada participante escribió. Confirma con la persona antes de suponer que una alergia es leve.';

  @override
  String get mealsDownloadPdf => 'Descargar PDF';

  @override
  String get mealsHint => 'Toca dos veces para ver quién no puede comer qué';

  @override
  String get mealsNotSubmitted => 'sin enviar';

  @override
  String mealsDownloadFailed(String detail) {
    return 'No se pudo guardar el PDF: $detail';
  }

  @override
  String get regStepHotel => 'Hotel';

  @override
  String get hotelTitle => '¿Te quedas antes o después?';

  @override
  String get hotelBody =>
      'Si llegas antes o te quedas después del tour, necesitarás hotel. Elige el nivel y cuántas noches.';

  @override
  String get hotelNoOptions =>
      'Los organizadores aún no definieron los niveles de hotel. Puedes volver más tarde.';

  @override
  String get hotelNone => 'No necesito hotel';

  @override
  String hotelPerNight(String amount) {
    return '$amount / noche';
  }

  @override
  String get hotelPriceTbd => 'Por definir';

  @override
  String get hotelNightsBefore => 'Noches antes del retiro';

  @override
  String get hotelNightsAfter => 'Noches después del tour';

  @override
  String hotelNightsCount(int count) {
    return '$count';
  }

  @override
  String get hotelEstimate => 'Costo estimado de hotel';

  @override
  String get hotelNotInFee =>
      'No está incluido en la cuota del retiro. Se paga aparte.';

  @override
  String get hotelSectionTitle => 'Niveles de hotel (antes / después)';

  @override
  String get hotelSectionHelp =>
      'Solo los participantes que vienen del exterior los ven. Eligen nivel y cantidad de noches.';

  @override
  String get hotelLevelKo => 'Nivel (coreano)';

  @override
  String get hotelLevelEn => 'Nivel (inglés)';

  @override
  String get hotelLevelEs => 'Nivel (español)';

  @override
  String get hotelPricePerNightLabel => 'Precio por noche';

  @override
  String get hotelAddLevel => 'Agregar nivel';

  @override
  String get hotelNoLevelsYet => 'Aún no agregaste niveles';

  @override
  String get summarySectionHotel => 'Hotel antes / después';

  @override
  String summaryHotelNights(int before, int after) {
    return '$before antes · $after después';
  }

  @override
  String hotelComputed(int before, int after) {
    return 'Necesitas $before noche(s) antes del retiro y $after noche(s) después.';
  }

  @override
  String hotelComputedBeforeOnly(int before) {
    return 'Necesitas $before noche(s) antes del retiro. No pudimos calcular las noches posteriores: falta tu vuelo de regreso.';
  }

  @override
  String hotelComputedAfterOnly(int after) {
    return 'Necesitas $after noche(s) después. No pudimos calcular las noches previas: falta tu vuelo de llegada.';
  }

  @override
  String get hotelComputedNone =>
      'Tus vuelos llegan y salen dentro del retiro, así que no necesitas hotel alrededor.';

  @override
  String get hotelNoFlightYet =>
      'Carga tus vuelos y calcularemos cuántas noches necesitas. También puedes indicarlas abajo.';

  @override
  String get hotelPickPrompt => 'Elige la opción que prefieras:';

  @override
  String get hotelAdjustHint =>
      'Calculado con tus vuelos y las fechas del retiro. Corrígelo abajo si no coincide.';

  @override
  String get hotelRecalc => 'Recalcular con mis vuelos';

  @override
  String get pcInviteLink => 'Enlace de invitación';

  @override
  String get pcInviteLinkHelp =>
      'Envía esto en lugar del UUID. Al abrirlo, la persona entra directo a este retiro, sin escribir ningún código.';

  @override
  String get pcCopyLink => 'Copiar enlace';

  @override
  String get pcLinkCopied => 'Enlace de invitación copiado';

  @override
  String get tgSectionTitle => 'Avisos por Telegram';

  @override
  String get tgSectionHelp =>
      'Las nuevas inscripciones y los cambios de este retiro se envían a tu Telegram. Déjalo vacío para usar el bot predeterminado.';

  @override
  String get tgBotToken => 'Token del bot';

  @override
  String get tgBotTokenHint => '123456789:AA…  (de @BotFather)';

  @override
  String get tgChatId => 'ID del chat';

  @override
  String get tgChatIdHint => 'ej. -1001234567890 (grupo) o tu ID de usuario';

  @override
  String get tgConfigured => 'Este retiro ya tiene un bot configurado';

  @override
  String get tgTokenHidden =>
      'El token guardado no se vuelve a mostrar. Déjalo vacío para conservarlo o escribe uno nuevo para reemplazarlo.';

  @override
  String get tgClearToken => 'Quitar el bot';

  @override
  String get tgInvalidToken =>
      'Eso no parece un token de bot (ej. 123456789:AA…)';

  @override
  String get tgHowTo =>
      'En Telegram, escribe a @BotFather → /newbot → copia el token. Agrega el bot a tu grupo y usa el ID de ese grupo.';

  @override
  String get hotelLevelPt => 'Nivel (portugués)';

  @override
  String get libTitle => 'Biblioteca';

  @override
  String get libSubtitle =>
      'Materiales compartidos en el retiro — ábrelos cuando quieras';

  @override
  String get libEmpty => 'Todavía no hay materiales.';

  @override
  String get libEmptyAdmin =>
      'Todavía no hay materiales. Usa el botón de abajo para agregar un PDF.';

  @override
  String get libOpen => 'Abrir';

  @override
  String get libAdd => 'Agregar material';

  @override
  String get libPickPdf => 'Elegir un PDF';

  @override
  String get libPickOnWeb =>
      'Los PDF se agregan desde el navegador de una computadora. Entra en ubf.coolsistema.com e inicia sesión allí.';

  @override
  String get libItemTitle => 'Título';

  @override
  String get libItemTitleHint => 'ej. Lección 1 — Juan 10';

  @override
  String get libItemDesc => 'Nota (opcional)';

  @override
  String get libPublished => 'Visible para los participantes';

  @override
  String get libHidden => 'Oculto';

  @override
  String get libUploading => 'Subiendo…';

  @override
  String libUploadFailed(String detail) {
    return 'No se pudo subir: $detail';
  }

  @override
  String get libDeleteTitle => '¿Eliminar este material?';

  @override
  String libDeleteBody(String title) {
    return '\"$title\" desaparecerá para todos y el archivo se elimina.';
  }

  @override
  String libSize(int kb) {
    return '$kb KB';
  }

  @override
  String libOpenFailed(String detail) {
    return 'No se pudo abrir el archivo: $detail';
  }

  @override
  String get libTitleRequired => 'Escribe un título';

  @override
  String get dashLibrarySubtitle =>
      'Comparte los PDF de las lecciones con los participantes';

  @override
  String get homeLibrary => 'Biblioteca del retiro';

  @override
  String get photoPick => 'Elegir del dispositivo';

  @override
  String get photoUploading => 'Subiendo…';

  @override
  String photoUploadFailed(String detail) {
    return 'No se pudo subir la foto: $detail';
  }

  @override
  String get photoOrUrl => 'o pega la dirección de una imagen';

  @override
  String get cardTitle => 'Mi tarjeta';

  @override
  String get cardShareTitle => 'Compartir por QR';

  @override
  String get cardShareIntro =>
      'Intercambia versículos, motivos de oración y contactos con quienes conoces.';

  @override
  String get cardPhoto => 'Foto';

  @override
  String get cardChangePhoto => 'Cambiar foto';

  @override
  String get cardVerseRef => 'Versículo';

  @override
  String get cardVerseRefHint => 'ej. Juan 10:10';

  @override
  String get cardVerseText => 'Texto del versículo (opcional)';

  @override
  String get cardPrayerTopics => 'Motivos de oración · hasta 3';

  @override
  String get cardPrayerHint => 'Uno por línea';

  @override
  String get cardContacts => 'Contactos — solo se muestra lo que actives';

  @override
  String get cardChannels => 'Canales';

  @override
  String get cardEmail => 'Correo';

  @override
  String get cardWhatsapp => 'WhatsApp';

  @override
  String get cardPhone => 'Teléfono';

  @override
  String get cardInstagram => 'Instagram';

  @override
  String get cardX => 'X';

  @override
  String get cardYoutube => 'YouTube';

  @override
  String get cardJuniorLocked =>
      'Tienes 19 años o menos, así que los datos de contacto quedan desactivados. Puedes compartir tu versículo, motivos de oración y canales.';

  @override
  String get cardShowQr => 'Mostrar mi QR';

  @override
  String get cardScan => 'Escanear un QR';

  @override
  String get cardQrHint => 'Cuando alguien lo escanea, se abre tu tarjeta.';

  @override
  String get cardQrRotate => 'Crear un QR nuevo';

  @override
  String get cardQrRotateWarn =>
      'El código anterior deja de funcionar de inmediato. Las personas que ya guardaste siguen en tu lista.';

  @override
  String get cardQrRotated => 'Se creó un QR nuevo';

  @override
  String get cardScanUnsupported =>
      'Escanear requiere cámara. Usa tu teléfono o abre el sitio en un navegador.';

  @override
  String get cardScanPoint => 'Apunta al QR de la otra persona';

  @override
  String get cardSaveFriend => 'Guardar como amigo';

  @override
  String get cardDontSave => 'No guardar';

  @override
  String get cardSaved => 'Guardado en tus amigos';

  @override
  String get cardAlreadySaved => 'Ya está en tus amigos';

  @override
  String get cardSelfScan => 'Esa es tu propia tarjeta';

  @override
  String get cardExpiredCode => 'Ese código expiró o no existe';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsEmpty =>
      'Todavía nadie. Escanea el QR de alguien después de conversar.';

  @override
  String get friendsSearch => 'Busca por nombre o país…';

  @override
  String friendsMetOn(String date) {
    return 'Se conocieron el $date';
  }

  @override
  String get friendsNote => 'Mi nota (solo tú la ves)';

  @override
  String get friendsRemove => 'Quitar de mi lista';

  @override
  String get friendsOtherPrograms => 'Otros retiros';

  @override
  String get cardPrivacyTitle => 'Ajustes de compartir';

  @override
  String get cardWhoCanSee => 'Quién puede abrir mi tarjeta';

  @override
  String get cardVisToken => 'Quienes escanean mi QR';

  @override
  String get cardVisProgram => 'Todos los del mismo retiro';

  @override
  String get cardVisProgramNote =>
      'Con esto activado, pueden abrir tu tarjeta desde la lista de participantes sin QR. Está desactivado por defecto.';

  @override
  String cardSavedBy(int count) {
    return 'Personas que guardaron mi tarjeta · $count';
  }

  @override
  String get cardSavedByEmpty => 'Todavía nadie guardó tu tarjeta.';

  @override
  String get cardRevoke => 'Cortar';

  @override
  String get cardRevokeDone => 'Ya no puede ver tu tarjeta';

  @override
  String get cardSaveBack => 'Guardar también';

  @override
  String get cardOpenWhatsapp => 'WhatsApp';

  @override
  String get cardOpenEmail => 'Correo';

  @override
  String get cardNoContacts => 'Esta persona no compartió datos de contacto.';

  @override
  String get homeQrShare => 'Compartir por QR';

  @override
  String get homeQrShareSub => 'Tu tarjeta, tu QR y la gente que conociste';

  @override
  String get companionSameBranch => 'Mismo capítulo que yo';

  @override
  String get companionSameBranchSub => 'Desactiva si pertenece a otro capítulo';

  @override
  String get companionMustRegister =>
      'Cada acompañante también debe inscribirse por su cuenta.';

  @override
  String get companionWhy =>
      'Los agregas aquí para que los ubiquen en la misma habitación. Si no te importa que los ubiquen por separado, no hace falta agregarlos.';

  @override
  String get homeAlsoAttending => 'Yo también asisto';

  @override
  String get homeAlsoAttendingSub =>
      'Inscríbete o abre la inscripción que ya completaste';

  @override
  String get homePickMyProgram => 'Entrar directo a uno de mis retiros';

  @override
  String get homeOrEnterUuid => 'O escribe el UUID del retiro de otra persona';

  @override
  String chapterNoticeTitle(String leader) {
    return 'Tu líder de capítulo $leader creó un retiro';
  }

  @override
  String get chapterNoticeAsk => '¿Deseas asistir?';

  @override
  String get chapterNoticeJoin => 'Sí, inscribirme';

  @override
  String get chapterNoticeLater => 'Ahora no';

  @override
  String get cpFeeDescHint => 'ej. habitación compartida, 3 comidas';

  @override
  String get cpFeeDescLooksLikeAmount =>
      'Esto parece un importe. Escribe el número en el campo de cuota de la izquierda; este campo es para lo que incluye.';

  @override
  String get cpFeeNoneWarning =>
      'No hay cuota definida, así que los participantes no ven la pantalla de cuota. Déjalo vacío solo si el retiro es gratuito.';

  @override
  String get rdyFeeTier => 'Nivel de cuota';

  @override
  String feeBackfillTitle(int count) {
    return '$count personas no eligieron nivel de cuota';
  }

  @override
  String get feeBackfillWhy =>
      'Se inscribieron antes de definir la cuota, así que no vieron esa pantalla. Su total no incluye la cuota del retiro.';

  @override
  String get feeBackfillAction => 'Ponerlas todas en…';

  @override
  String feeBackfillConfirm(int count, String tier) {
    return '¿Poner a $count personas en $tier y recalcular sus totales? Quienes ya eligieron no se tocan.';
  }

  @override
  String feeBackfillDone(int count) {
    return 'Se actualizaron $count personas';
  }

  @override
  String get feeBackfillNotSet =>
      'Ese nivel todavía no tiene importe. Define la cuota primero.';

  @override
  String get studyLangMulti =>
      'Elige todos los idiomas en los que puedes estudiar';

  @override
  String get studyLangPrimary => 'Principal';

  @override
  String get studyLangPrimaryNote =>
      'El primero que elijas es tu idioma principal: tu equipo de estudio se forma con ese. Los demás ayudan a ubicarte si un equipo queda pequeño.';

  @override
  String get regStepPickup => 'Traslado';

  @override
  String get pickupTitle => '¿Necesitas traslado al lugar?';

  @override
  String get pickupBody =>
      'Vienes desde el país anfitrión, así que no necesitamos tu vuelo. Solo si te recogemos y desde dónde.';

  @override
  String get pickupNeed => 'Necesito traslado';

  @override
  String get pickupNeedNo => 'Voy por mi cuenta';

  @override
  String get pickupFromLabel => '¿Dónde te recogemos?';

  @override
  String get pickupFromHint => 'ej. terminal de Retiro, frente al capítulo';

  @override
  String get pickupFromRequired => 'Escribe dónde te recogemos';

  @override
  String get cpFeeMoveTitle =>
      'Los importes están en los campos de descripción';

  @override
  String get cpFeeMoveBody =>
      'Como los campos de importe están vacíos, los participantes no ven la pantalla de cuota. ¿Los movemos?';

  @override
  String get cpFeeMoveAction => 'Mover a los campos de cuota';

  @override
  String get cpFeeMoveDone => 'Listo. Pulsa Guardar para conservarlo.';

  @override
  String get tblTitle => 'Detalle';

  @override
  String tblCount(int count) {
    return '$count filas';
  }

  @override
  String get tblEmpty => 'No hay nada que mostrar.';

  @override
  String get tblExportPdf => 'PDF';

  @override
  String get tblExportExcel => 'Excel';

  @override
  String tblExportFailed(String detail) {
    return 'No se pudo exportar: $detail';
  }

  @override
  String get tblHint => 'Toca dos veces para ver la lista';

  @override
  String get colGenderAge => 'Sexo / Edad';

  @override
  String get colStatus => 'Estado';

  @override
  String get colFlight => 'Vuelo de llegada';

  @override
  String get colPayment => 'Pago';

  @override
  String get colFee => 'Cuota';

  @override
  String get colLanguages => 'Idiomas';

  @override
  String get tblAllAttendees => 'Todos los participantes';

  @override
  String epPlanDocs(int count) {
    return 'Documentos del plan ($count)';
  }

  @override
  String get epPlanUpload => 'Subir un PDF';

  @override
  String get epPlanName => '¿Qué es este documento?';

  @override
  String get epPlanNameHint => 'p. ej. Itinerario, Costos, Inscripción';

  @override
  String get epPlanRemove => 'Quitar este documento';

  @override
  String epPlanFull(int max) {
    return 'Hasta $max documentos.';
  }

  @override
  String get tourPlanOpen => 'Abrir';

  @override
  String get tourOpenFailed => 'No se pudo abrir; se copió el enlace.';

  @override
  String get dashStatTours => 'Inscripciones a tours';

  @override
  String get tblTourSignups => 'Inscripciones a tours';

  @override
  String get colTour => 'Tour';

  @override
  String get colSignups => 'Inscritos';

  @override
  String get colRemaining => 'Quedan';

  @override
  String get colDeadline => 'Cierra';

  @override
  String get tourNoLimit => 'sin límite';

  @override
  String get tourNobody => 'Todavía nadie se inscribió';

  @override
  String tourSignupSummary(int signed) {
    return '$signed inscritos';
  }

  @override
  String get tblUnfinishedNote =>
      'Una fila color crema significa que aún no terminó el registro.';

  @override
  String get asnTabService => 'Servicio';

  @override
  String svcNeeded(int filled, int needed) {
    return '$filled de $needed';
  }

  @override
  String svcNoLimit(int filled) {
    return '$filled · sin meta';
  }

  @override
  String svcShort(int count) {
    return 'faltan $count';
  }

  @override
  String get svcNobody => 'Todavía nadie';

  @override
  String get svcNominate => 'Pedir a alguien';

  @override
  String get svcPickPerson => '¿A quién le pedimos?';

  @override
  String svcAsked(String name) {
    return 'Se lo pedimos a $name';
  }

  @override
  String get svcSetLead => 'Hacer responsable';

  @override
  String get svcLead => 'Responsable';

  @override
  String get svcConfirm => 'Confirmar';

  @override
  String get svcReject => 'Rechazar';

  @override
  String get svcEditRoles => 'Agregar roles · fijar cantidades';

  @override
  String get svcAddRole => 'Agregar un rol';

  @override
  String get svcRoleName => 'Nombre del rol';

  @override
  String get svcRoleNameHint => 'p. ej. Guía del bus a Iguazú';

  @override
  String get svcNeedCount => '¿Cuántos?';

  @override
  String get svcNeedsApproval => 'Requiere aprobación';

  @override
  String get svcStatusInvited => 'Esperando respuesta';

  @override
  String get svcStatusApplied => 'Se ofreció';

  @override
  String get svcStatusApproval => 'Esperando aprobación';

  @override
  String get svcStatusConfirmed => 'Confirmado';

  @override
  String get svcStatusRejected => 'Rechazado';

  @override
  String get svcStatusDeclined => 'Dijo que no';

  @override
  String get svcRoleSpecialSong => 'Canto especial';

  @override
  String get svcRoleMc => 'Presentador';

  @override
  String get svcRolePickup => 'Traslados';

  @override
  String get svcRoleCleaning => 'Limpieza';

  @override
  String get svcRoleTourGuide => 'Guía del tour';

  @override
  String get svcRoleMealPrep => 'Preparar comidas';

  @override
  String get svcRoleLodgingBackup => 'Apoyo de alojamiento';

  @override
  String get svcRoleRegistrationDesk => 'Mesa de inscripción';

  @override
  String get svcRoleInterpreter => 'Intérprete';

  @override
  String get svcRolePhotoVideo => 'Foto y video';

  @override
  String get svcRoleMedical => 'Salud';

  @override
  String get svcRoleGroupStudyLeader => 'Líder de grupo de estudio';

  @override
  String get svcRoleOther => 'Otro';

  @override
  String get svcInviteTitle => 'Te pidieron ayuda';

  @override
  String svcInviteBody(String role) {
    return '¿Podrías encargarte de $role?';
  }

  @override
  String get svcAccept => 'Sí, puedo';

  @override
  String get svcDecline => 'Lo siento, no puedo';

  @override
  String get svcThanks => 'Gracias.';

  @override
  String get admTitle => 'Quién puede administrarla';

  @override
  String get admSubtitle =>
      'Ven el panel, la lista de participantes y las asignaciones.';

  @override
  String get admOwner => 'La creó';

  @override
  String get admAdd => 'Agregar a alguien';

  @override
  String get admPickPerson => 'Elegir de la lista';

  @override
  String get admByEmail => '¿No está en la lista? Usa su correo';

  @override
  String get admEmailLabel => 'El correo con el que inicia sesión';

  @override
  String get admRemove => 'Quitar';

  @override
  String admRemoveAsk(String name) {
    return '¿Quitar a $name de los administradores?';
  }

  @override
  String admAdded(String name) {
    return '$name ya puede administrarla';
  }

  @override
  String get admOwnerLocked => 'Quien la creó no puede ser quitado.';

  @override
  String get dashAdmins => 'Administradores';

  @override
  String get dashAdminsSub => 'Da acceso a la lista y las asignaciones';

  @override
  String get svcRolesTitle => 'Roles de esta conferencia';

  @override
  String svcRoleCount(int count, int max) {
    return '$count de $max roles';
  }

  @override
  String get svcSectionCustom => 'Roles que creaste';

  @override
  String get svcSectionBuiltIn => 'Roles predefinidos';

  @override
  String svcRoleFull(int max) {
    return 'Hasta $max roles.';
  }

  @override
  String get svcDeleteRole => 'Eliminar este rol';

  @override
  String get svcNeedShort => 'faltan';

  @override
  String dashMoreCount(int count) {
    return 'Ver los otros $count →';
  }

  @override
  String get dashSeeAll => 'Abrir la tabla →';

  @override
  String get dashByTour => 'Ver tour por tour →';

  @override
  String get dashPreviewEmpty => 'Todavía nada';

  @override
  String get dashTourNobody => 'sin inscritos';

  @override
  String get dashTourRoom => 'hay lugar';

  @override
  String get dashTourFull => 'lleno';

  @override
  String dashUnitPeopleShort(int count) {
    return '$count';
  }

  @override
  String epContacts(int count) {
    return 'Contactos en el lugar ($count)';
  }

  @override
  String get epAddContact => 'Agregar contacto';

  @override
  String get epContactName => 'Nombre';

  @override
  String get epContactPhone => 'Teléfono';

  @override
  String get epRemoveContact => 'Quitar este contacto';

  @override
  String epContactsFull(int max) {
    return 'Hasta $max contactos.';
  }

  @override
  String get epPaymentWhen => '¿Cuándo se paga?';

  @override
  String get epFeeWhen => 'Cuota de la conferencia';

  @override
  String get epTourWhen => 'Costo de los tours';

  @override
  String get epPrepaid => 'Por adelantado';

  @override
  String get epOnsite => 'Al llegar';

  @override
  String get epPaymentNote =>
      'Si ambos se pagan al llegar, la tarjeta de pagos se oculta del panel.';

  @override
  String get dashStatPayments => 'Pagos';

  @override
  String get dashPayConfirmed => 'pagado';

  @override
  String get dashPayPending => 'esperando';

  @override
  String get dashPayNone => 'sin pagar';

  @override
  String get tblPayments => 'Pagos';

  @override
  String get setupExtraBed => 'Lugar extra';

  @override
  String get setupExtraBedHint =>
      'Cabe una persona más. Solo se usa cuando se llenan las camas normales.';

  @override
  String asnRoomWithExtra(int used, int cap, int extra) {
    return '$used/$cap (+$extra)';
  }

  @override
  String setupExtraSeats(int count) {
    return 'extra $count';
  }

  @override
  String get dashStatVolunteers => 'Voluntarios';

  @override
  String dashRoleFilled(int filled, int needed) {
    return '$filled/$needed';
  }

  @override
  String get dashOpenService => 'Abrir el panel de servicio →';

  @override
  String svcOffered(int count) {
    return 'Se ofrecieron ($count)';
  }

  @override
  String get svcOfferedNote =>
      'Lo que dijeron que pueden hacer. A quién se lo pides sigue siendo tu decisión.';

  @override
  String get svcCanDo => 'puede';

  @override
  String get svcCallSend => 'Pedir ayuda a todos';

  @override
  String svcCallSent(int short) {
    return 'Pedido · faltan $short';
  }

  @override
  String get svcCallClose => 'Dejar de pedir';

  @override
  String get svcCallDone => 'Enviado a todos';

  @override
  String get svcCallTooSoon => 'Ya lo pediste hace poco. Espera unas horas.';

  @override
  String get svcCallFilled => 'Este rol ya está cubierto.';

  @override
  String get svcCallNoTarget => 'Primero define cuántos necesitas.';

  @override
  String get svcOpenTitle => 'Se necesita ayuda';

  @override
  String svcOpenBody(String role, int short) {
    return '$role — faltan $short';
  }

  @override
  String get svcIllDoIt => 'Yo lo hago';

  @override
  String get svcAppliedThanks => 'Gracias. El organizador lo confirmará.';

  @override
  String get annTitle => 'Enviar un aviso';

  @override
  String get annSubtitle => 'Llega a los teléfonos, no solo al chat grupal';

  @override
  String get annBody => '¿Qué quieres decir?';

  @override
  String get annSend => 'Enviar';

  @override
  String get annTo => 'Quién lo recibe';

  @override
  String get annToAll => 'Todos';

  @override
  String get annToRoom => 'Una habitación';

  @override
  String get annToGroup => 'Un grupo de estudio';

  @override
  String get annToUnsub => 'No terminaron el registro';

  @override
  String get annToUnpaid => 'Aún no pagaron';

  @override
  String get annPickRoom => '¿Cuál habitación?';

  @override
  String get annPickGroup => '¿Cuál grupo?';

  @override
  String annSent(int count) {
    return 'Enviado a $count dispositivos';
  }

  @override
  String get annPast => 'Avisos anteriores';

  @override
  String get annNoneYet => 'Todavía no enviaste nada';

  @override
  String get dashAnnounce => 'Avisar a los participantes';

  @override
  String get dashAnnounceSub => 'A todos, o solo a una habitación o grupo';

  @override
  String get dspPlanTitle => 'Qué hace falta';

  @override
  String dspPlanNeed(int need, int add) {
    return '$need hacen falta · faltan $add';
  }

  @override
  String dspPlanOk(int have) {
    return '$have · cubierto';
  }

  @override
  String dspPlanPeople(int count) {
    return '$count personas';
  }

  @override
  String dspMakeVans(int count) {
    return 'Crear $count van(s)';
  }

  @override
  String get dspPlanNone => 'Todavía no hay horarios';

  @override
  String get dspUnassignedFlight => 'sin van';

  @override
  String get schServiceLabel => 'Servicio necesario (opcional)';

  @override
  String get schServiceNone => 'Ninguno';

  @override
  String get schServiceHint =>
      'El recordatorio dirá cuántos faltan, solo si faltan.';

  @override
  String svcAssignTo(String name) {
    return 'Pedir a $name que ayude con';
  }

  @override
  String get svcSuggested => 'coincide con lo que ofreció';

  @override
  String get dashNotAssigned => 'sin tarea todavía';

  @override
  String dashAssignedCount(int count) {
    return 'asignado a $count';
  }

  @override
  String get asnNoRoomLeader => 'sin encargado de cuarto';

  @override
  String asnRoomLeaderIs(String name) {
    return 'Encargado del cuarto: $name';
  }

  @override
  String get asnNoGroupLeader => 'sin líder';

  @override
  String get svcMineTitle => 'En qué ayudo';

  @override
  String get tgOffer => 'Recibir avisos también por Telegram';

  @override
  String get tgOpen => 'Abrir Telegram';

  @override
  String get tgCheck => 'Ya lo hice';

  @override
  String get tgLinked => 'Telegram está conectado';

  @override
  String get tgNotYet =>
      'Todavía no — abre el enlace, pulsa Iniciar y vuelve a intentarlo';

  @override
  String get tgUnlink => 'Desconectar';

  @override
  String svcAskThem(int count) {
    return 'Pedir ($count)';
  }

  @override
  String get epRoutes => 'Otras formas de llegar';

  @override
  String get epRoutesDesc =>
      'No todos llegan al mismo aeropuerto. Indique las otras rutas.';

  @override
  String get epRouteAirport => 'Aeropuerto';

  @override
  String get epRouteNote => 'Cómo se llega desde allí';

  @override
  String get epRouteNoteHint => 'ej.: Buenos Aires y 4 horas en micro';

  @override
  String get epAddRoute => 'Agregar ruta';

  @override
  String get epRemoveRoute => 'Quitar esta ruta';

  @override
  String get flightNoteLabel => 'Algo que agregar (opcional)';

  @override
  String get flightNoteHint => 'ej.: llego a EZE y sigo en micro';

  @override
  String get immCardOtherRoute => 'OTHER ROUTE / otra ruta';

  @override
  String get svcWillConfirm => 'se ofreció para esto — se asigna de inmediato';

  @override
  String get svcWillAsk => 'no se ofreció — se le va a preguntar';

  @override
  String get setupGroupLanguage => 'Idioma en que estudia este grupo';

  @override
  String get setupAnyLanguage => 'Sin definir';

  @override
  String get setupCoupleRooms => 'Cuartos de matrimonio · familia';

  @override
  String get setupDormRooms => 'Cuartos compartidos';

  @override
  String get setupRoomsMadeName => 'Nombre del cuarto';

  @override
  String get setupGroupCapacityHint =>
      'Déjelo vacío y la asignación automática reparte parejo';

  @override
  String get tblAmountDue => 'Monto a pagar';

  @override
  String get tblSubmittedHint => 'Actívelo si tomó su formulario en papel';

  @override
  String get annToService => 'Un equipo de servicio';

  @override
  String get annPickService => '¿A qué equipo?';

  @override
  String get payUnpaid => 'Sin pagar';

  @override
  String get payPartial => 'Pago parcial';

  @override
  String get payPaid => 'Pagado';

  @override
  String get payPending => 'Por verificar';

  @override
  String get tblAmountPaid => 'Monto recibido';

  @override
  String get sumWanting => 'Van a venir';

  @override
  String get sumCollected => 'Recaudado';

  @override
  String get sumRemaining => 'Falta cobrar';

  @override
  String get ledgerTitle => 'Caja';

  @override
  String get ledgerAdd => 'Agregar un movimiento';

  @override
  String get ledgerEmpty => 'Todavía no hay nada anotado';

  @override
  String get ledgerIncome => 'Entró';

  @override
  String get ledgerExpense => 'Salió';

  @override
  String get ledgerWhat => 'Concepto';

  @override
  String get ledgerAmount => 'Monto';

  @override
  String get ledgerNote => 'Nota (opcional)';

  @override
  String get ledgerCollected => 'Inscripciones cobradas';

  @override
  String get ledgerSupport => 'Apoyo recibido';

  @override
  String get ledgerSpent => 'Gastado';

  @override
  String get ledgerBalance => 'En caja';

  @override
  String get ledgerExpected => 'Si todos pagan';

  @override
  String ledgerOwedNote(String amount) {
    return 'Falta cobrar $amount';
  }

  @override
  String get dashLedgerSub => 'Apoyos, gastos y lo que queda';

  @override
  String get ledgerAddExpense => 'Anotar gasto';

  @override
  String get ledgerAddIncome => 'Anotar apoyo';

  @override
  String ledgerCount(int count) {
    return '$count movimientos';
  }

  @override
  String ledgerLocalAmount(String code) {
    return 'Monto en $code';
  }

  @override
  String ledgerRate(String code, String base) {
    return '$code por 1 $base';
  }

  @override
  String get ledgerRateBlue => 'dólar blue de hoy — cámbielo si usó otro';

  @override
  String get ledgerRateMarket => 'cotización de hoy — cámbiela si usó otra';

  @override
  String get ledgerRateUnavailable =>
      'No se pudo traer la cotización. Escriba la que usó.';

  @override
  String get rosterNoName => 'Sin nombre cargado';

  @override
  String rosterAccountName(String name) {
    return '$name (nombre de la cuenta)';
  }

  @override
  String get regNameFromAccount =>
      'Tomado de su cuenta — cámbielo si no corresponde';

  @override
  String get statByCountry => 'POR PAÍS';

  @override
  String get statByGender => 'POR SEXO';

  @override
  String get statByAge => 'POR EDAD';

  @override
  String get statUnknown => 'Sin cargar';

  @override
  String get statAgeUnder20 => 'Menos de 20';

  @override
  String get statAge70Plus => '70 o más';

  @override
  String statAgeDecade(int from, int to) {
    return '$from–$to';
  }
}
