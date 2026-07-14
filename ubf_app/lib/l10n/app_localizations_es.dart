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
  String get regBranch => 'Nombre de la sede *';

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
  String get summaryBranch => 'Sede';

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
  String get cpPeriod => 'Select period (start ~ end)';

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
    return 'Fotos ($count/5)';
  }

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
      'Las solicitudes de compañero de cuarto solo pueden enviarse al mismo género.';

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
}
