# Glosario (Espanol)

> Este archivo de referencia se carga automaticamente para usuarios no tecnicos (Level: non-technical). Define todos los terminos tecnicos usados en las conversaciones de AgentBloc.

## Proposito

Definiciones en lenguaje sencillo de todos los terminos tecnicos usados en las conversaciones de AgentBloc. Se carga automaticamente para usuarios no tecnicos (Level: non-technical).

## Conceptos Principales de AgentBloc

**Agente**: Un asistente de IA especializado que realiza una tarea especifica en tu flujo de trabajo. Cada agente tiene un rol claro, como "Recolector de Facturas" o "Enviador de Reportes."

**Equipo de Agentes**: Un grupo de agentes que trabajan juntos para automatizar tu proceso de negocio. Cada agente se encarga de una responsabilidad, y se coordinan mediante una topologia definida.

**Artefacto**: Un archivo de configuracion generado por AgentBloc que indica a tus agentes como ejecutarse. Ejemplos incluyen team.yaml (lista del equipo), agent.yaml (instrucciones individuales) y governance.yaml (reglas de seguridad).

**Radio de Impacto (Blast-Radius)**: Una puntuacion de seguridad del 1 (seguro, solo lectura) al 4 (puede enviar mensajes al exterior). Los agentes con puntuacion 3 o superior necesitan tu aprobacion antes de actuar.

**Contrato**: Una especificacion de lo que hace un agente: sus entradas, salidas, herramientas, horario y manejo de errores. Es como la descripcion del puesto de trabajo del agente.

**Ejecucion de Prueba (Dry Run)**: Una ejecucion de prueba donde los agentes procesan datos reales pero no envian correos, realizan pagos ni modifican servicios externos. Un paso de seguridad obligatorio antes de entrar en produccion.

**Bucle de Evolucion (Evolution Loop)**: Una verificacion semanal automatizada que vigila nuevas capacidades o problemas de seguridad que afecten a tu equipo de agentes, y propone cambios para tu aprobacion.

**Puerta (Gate)**: Un punto de control entre fases. Debes confirmar explicitamente ("si", "aprobado", "adelante") antes de que AgentBloc pase a la siguiente fase. Las puertas previenen decisiones prematuras.

**Gobernanza**: El conjunto de reglas que controlan lo que tus agentes pueden y no pueden hacer: presupuestos, permisos, limites de frecuencia, registro de auditoria y requisitos de cumplimiento.

**Kill Switch**: Un boton de parada de emergencia que detiene toda la actividad de los agentes inmediatamente. Un mecanismo simple basado en archivos que los agentes verifican antes de cada ejecucion.

**Fase (Phase)**: Una de las seis etapas del proceso AgentBloc: Entrevista, Diseno, Analisis de Integraciones, Confirmacion + Ejecucion de Prueba, Despliegue y Evolucion.

**Divulgacion Progresiva (Progressive Disclosure)**: Un patron de diseno donde AgentBloc te muestra solo la informacion relevante al paso actual, cargando mas detalle segun sea necesario. Mantiene las conversaciones enfocadas.

**Archivo de Estado (State File)**: Un archivo JSON donde los agentes guardan su progreso, como que facturas se han procesado o que pagos se han emparejado. Garantiza que los agentes nunca dupliquen trabajo.

**Subagente**: Un agente que se ejecuta dentro de la sesion de otro agente con herramientas restringidas y contexto aislado. Se usa para delegar subtareas especificas de forma segura.

**Topologia**: La disposicion de como los agentes se conectan y comunican entre si. Los cuatro tipos son Pipeline, Jerarquia, Malla y Enjambre.

**Topologia: Jerarquia (Hierarchy)**: Un agente coordinador dirige a multiples agentes trabajadores y recopila sus resultados. Como un gerente delegando tareas a su equipo.

**Topologia: Malla (Mesh)**: Los agentes colaboran como iguales, cada uno refinando un resultado compartido. Como un grupo editando el mismo documento juntos.

**Topologia: Pipeline**: Agentes dispuestos en cadena donde cada uno pasa su resultado al siguiente. Como una linea de ensamblaje.

**Topologia: Enjambre (Swarm)**: Los agentes exploran de forma independiente en paralelo, con resultados fusionados despues. Se usa para investigacion o recopilacion de datos de muchas fuentes.

## Integracion y Tecnico

**API**: Una forma en que los programas de software se comunican entre si. Como un buzon digital entre servicios.

**Cron**: Un programador automatico que ejecuta tus agentes en horarios especificos, como "todos los dias a las 22:00." Usa el sistema estandar de programacion de Unix.

**Matriz de Decision (Decision Matrix)**: Una tabla comparativa que clasifica las opciones de integracion para un servicio segun confianza, esfuerzo de configuracion y capacidades. Ayuda a elegir el mejor conector.

**Cadena de Respaldo (Fallback Chain)**: Un plan de respaldo para cada integracion. Si el metodo preferido falla (la API esta caida), el agente intenta automaticamente la siguiente opcion (automatizacion del navegador, luego extraccion de correo).

**Servidor MCP**: Un conector que permite a los agentes de IA comunicarse con servicios externos como Google Sheets, Telegram o Shopify. Significa Model Context Protocol (Protocolo de Contexto de Modelo).

**OAuth**: Un metodo de inicio de sesion seguro donde concedes acceso limitado a un servicio sin compartir tu contrasena. El estandar de oro para credenciales de agentes.

**Playwright**: Una herramienta de automatizacion de navegador que permite a los agentes interactuar con sitios web como lo haria un humano, haciendo clic en botones y leyendo paginas. Se usa cuando no existe una API.

**Puntuacion de Confianza (Trust Score)**: Una calificacion (ALTA, MEDIA, BAJA) asignada a cada integracion segun quien la mantiene, con que frecuencia se actualiza y cuan ampliamente se usa.

**Webhook**: Una notificacion que se dispara automaticamente cuando algo ocurre en un servicio. Como un timbre que suena cuando llega un nuevo pedido.

## Seguridad y Cumplimiento

**Registro de Auditoria (Audit Log)**: Un registro detallado y a prueba de manipulaciones de todo lo que hacen tus agentes: a que accedieron, que cambiaron y cuando. Requerido para cumplimiento normativo y depuracion.

**ID de Correlacion (Correlation ID)**: Un codigo de seguimiento unico que vincula todas las acciones de una sola ejecucion de agente. Como un numero de recibo que conecta todos los articulos de una compra.

**Jerarquia de Credenciales (Credential Hierarchy)**: El principio de dar a cada agente el acceso menos poderoso que necesite. Orden de preferencia: OAuth (mas seguro) > clave API con alcance limitado > token de administrador (mas riesgoso).

**Clasificacion de Datos (Data Classification)**: El proceso de etiquetar cada dato en tu flujo de trabajo como DPI, DPS, financiero o publico. Determina que reglas de seguridad se activan.

**DSAR (Data Subject Access Request)**: Una solicitud formal de una persona para ver, corregir o eliminar sus datos personales. Requerido bajo el RGPD.

**RGPD (GDPR)**: El Reglamento General de Proteccion de Datos de la Union Europea. Reglas de privacidad obligatorias para cualquier negocio que maneje datos personales de la UE.

**HIPAA**: Una regulacion estadounidense que protege la informacion de salud. Se activa automaticamente cuando tu flujo de trabajo maneja datos de pacientes o medicos.

**PCI**: Estandar de Seguridad de Datos de la Industria de Tarjetas de Pago. Se activa cuando tu flujo de trabajo maneja numeros de tarjetas de credito o datos de pago.

**DPI (Datos Personales Identificables / PII)**: Cualquier dato que pueda identificar a una persona especifica: nombres, correos electronicos, numeros de telefono, direcciones, documentos de identidad.

**DPS (Datos Personales de Salud / PHI)**: Datos de salud vinculados a una persona especifica: diagnosticos, prescripciones, expedientes medicos, identificadores de seguro medico.

**Inyeccion de Prompt (Prompt Injection)**: Un ataque donde instrucciones maliciosas se ocultan dentro de datos que un agente procesa (correos, paginas web), intentando enganar al agente para que haga algo danino.

**Limitacion de Frecuencia (Rate Limiting)**: Un tope sobre cuantas acciones puede realizar un agente en un periodo de tiempo. Previene costos desbocados y spam accidental.

**Aislamiento de Inquilinos (Tenant Isolation)**: Mantener los datos de un cliente completamente separados de los de otro. Critico cuando un solo despliegue de AgentBloc sirve a multiples negocios.

## Despliegue y Operaciones

**ClaudeClaw / Definicion de Trabajo (Job Definition)**: Un archivo markdown que indica a Claude Code exactamente que hacer en una ejecucion programada. El agente lee este archivo como su informe de mision cada vez que cron lo activa.

**Idempotencia (Idempotency)**: Una garantia de que ejecutar la misma tarea dos veces produce el mismo resultado sin duplicar trabajo. Como presionar el boton del ascensor multiples veces solo llama al ascensor una vez.

**Disciplina de Notificaciones (Notification Discipline)**: La regla de que los agentes permanecen en silencio a menos que algo notable ocurra. Sin mensajes de "todo esta bien" inundando tu telefono.

**Esquema de Estado (State Schema)**: La estructura definida de un archivo de estado, especificando que campos contiene y que valores son validos. Garantiza que los agentes lean y escriban el estado de forma consistente.

**Hilo de Telegram (Telegram Thread)**: Un hilo de conversacion dedicado en Telegram donde un agente o dominio especifico envia sus notificaciones. Mantiene los reportes de diferentes agentes organizados.
