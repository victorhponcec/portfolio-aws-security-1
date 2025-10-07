# Portafolio de Seguridad AWS: Asegurando una Arquitectura de 3 Capas
**Autor:** Victor Ponce | **Contacto:** [Linkedin](https://www.linkedin.com/in/victorhugoponce)

English Version: [README.md](https://github.com/victorhponcec/portfolio-aws-security-1/blob/main/README.md)

## 1. Resumen

Este proyecto se enfoca en una arquitectura segura en AWS, construida con Terraform (IaC). El objetivo es mostrar mis habilidades en ingeniería de seguridad en nube, integrando controles de defensa en profundidad, en redes, identidad, monitoreo y las distintas capas de la aplicación.

La solución base consiste en una aplicación de 3 capas (Web, App y base de datos) con fuertes medidas de seguridad: subredes privadas, reglas estrictas en Grupos de Seguridad, logging centralizado, detección de amenazas, protección en el borde y capa 7, revisiones automáticas de cumplimiento, entre otros. Todo esto alineado con el marco AWS Well-Architected.

## 2. Diagrama de Arquitectura

<div align="center">

![Overview Diagram](README/diagramv3.png)
<p><em>(img. 1 – Diagrama de Arquitectura)</em></p>
</div>

## 3. Infraestructura

Las soluciones de seguridad implementadas giran en torno a una aplicación de arquitectura de 3 capas: web, app y base de datos. Cada capa tiene reglas de seguridad estrictas, las cuales controlan el tráfico entre y hacia ellas. En la tabla 1 se detallan los elementos que componen cada capa.  

<div align="center">

| Tier              | Subnets / AZs                                                  | Recursos                                                                        | Notas                                 |
| ----------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------- |
| **Capa Web**      | Private Subnet E (us-east-1a)<br>Private Subnet F (us-east-1b) | Auto Scaling Group<br>Internet-facing Application Load Balancer                  | Solo recibe tráfico de CloudFront     |
| **Capa App**      | Private Subnet A (us-east-1a)<br>Private Subnet B (us-east-1b) | Auto Scaling Group<br>Internal Application Load Balancer                         | Se comunica con Web + DB              |
| **Capa base de datos** | Private Subnet C (us-east-1a)<br>Private Subnet D (us-east-1b) | RDS for SQL                                                                      | Encriptado, sin acceso público        |
| **Subred Publica**        | Public Subnet A (us-east-1a)<br>Public Subnet B (us-east-1b)   | Break Glass Server (EC2)<br>NAT Gateway (us-east-1a)<br>NAT Gateway (us-east-1b) | NAT para subnets privadas             |

<p><em>(Tabla 1 – Infraestructura de la Arquitectura de tres capas)</em></p>
</div>

Las capas Web y App se encuentran en dos subredes privadas diferentes, distribuidas en dos zonas de disponibilidad para efectos de redundancia. Ambas capas tienen acceso de salida a internet a través de dos NAT Gateways, uno en cada zona de disponibilidad (AZ); esto para garantizar parchado, updates e instalación de software. 

La capa Web sirve su contenido a través de CloudFront, y actúa cómo un puente entre el usuario y la aplicación, la cual recibe las solicitudes del usuario por medio de su interfaz web, e interactúa con la App para procesar las solicitudes. La capa Web escala on-demand por medio de un Grupo de escalado automático (ASG), es que es gatillado por métricas basadas en el uso de CPU. Un Equilibrador de carga de aplicación (ALB) expuesto a internet distribuye el tráfico hacia la capa Web. Cada AZ cuenta con un ALB, para garantizar disponibilidad.  

La capa de la App recibe y procesa las solicitudes desde la capa Web, a través de un ALB interno, e interactúa directamente con la base de datos. La App también corre sobre ASG, es cúal es gatillado por métricas de CPU. 

En las tablas 2 y 3 se detalla la lógica de escalado automático. 

<div align="center">

| **CloudWatch Metric Alarm (WEB ASG)** |           |
| ------------------------------------- | --------- |
| **Parameter**                         | **Value** |
| Metric                                | CPU       |
| Threshold                             | 70        |
| Evaluation Periods                    | 2         |
| Period (seconds)                      | 30        |
<p><em>(Tabla 2 – CloudWatch metric alarm para ASG WEB)</em></p>

| **CloudWatch Metric Alarm (APP ASG)** |           |
| ------------------------------------- | --------- |
| **Parameter**                         | **Value** |
| Metric                                | CPU       |
| Threshold                             | 60        |
| Evaluation Periods                    | 3         |
| Period (seconds)                      | 30        |
<p><em>(Tabla 3 – CloudWatch metric alarm para ASG App)</em></p>
</div>

En la capa web hay una base de datos RDS con MySQL, la cual cuenta con replicación síncrona a una segunda zona de disponibilidad, en caso de desastre. La capa de base de datos solo interactúa con la capa App, haciéndose cumplir por reglas de seguridad.

## 4. Flujo

Los usuarios acceden a la App a través de un dominio público configurado en Route 53, el cual va a una distribución CloudFront para servir las solicitudes en el borde (edge). Adicionalmente CloudFront está protegido por un Web Application Firewall (WAF). El ALB expuesto a internet actúa cómo origen de CloudFront y recibe todo el tráfico que no pase por el caché; este tráfico es distribuido a la capa Web (ASG). La App procesa las solicitudes provenientes de la capa Web y lee/escribe en la base de datos. 

## 5. Seguridad de Red

Todas las capas se encuentran en subredes privadas, y la comunicación entre capas es restringida por grupos de seguridad. La capa Web se puede comunicar con el ALB expuesto a internet y con la capa App. El ALB solo acepta tráfico desde CloudFront. La capa App tiene comunicación directa con las capas Web y de base de datos, mientras que la capa de base de datos solo tiene acceso a la capa de la App (y al servidor break-glass de emergencia). Las reglas y grupos de seguridad se detallan en la siguiente tabla: 

<div align="center">

| Security Group      | Dirección | Origen / Destino      | Protocolo | Puerto(s) | Descripción                                            | Notas |
| ------------------- | --------- | --------------------- | --------- | --------- | ------------------------------------------------------ | ----- |
| **web**             | Ingress   | SG: lba               | TCP       | 80, 443   | Permitir HTTP/HTTPS desde Load Balancer                |       |
| web                 | Ingress   | SG: app               | TCP       | 443       | Permitir HTTPS desde capa App                          |       |
| web                 | Ingress   | SG: break_glass       | TCP       | 22        | Permitir acceso de emergencia                          |       |
| web                 | Egress    | 0.0.0.0/0             | ALL       | ALL       | Permitir todo el tráfico de salida                     |       |
| **lba**             | Ingress   | com.amazonaws.global cloudfront.origin-facing | TCP | 443 | Lista de prefijos administrada por AWS para CloudFront |       |
| lba                 | Egress    | 0.0.0.0/0             | ALL       | ALL       | Permitir todo el tráfico de salida                     |       |
| **app**             | Ingress   | SG: web               | TCP       | 80, 443   | Permitir HTTP/HTTPS desde capa Web                     |       |
| app                 | Ingress   | SG: break_glass       | TCP       | 22        | Permitir acceso de emergencia                          |       |
| app                 | Egress    | 0.0.0.0/0             | ALL       | ALL       | Permitir todo el tráfico de salida                     |       |
| **lbb**             | Ingress   | SG: web               | TCP       | 80, 443   | Permitir HTTP/HTTPS desde capa Web                     |       |
| lbb                 | Egress    | 0.0.0.0/0             | ALL       | ALL       | Permitir todo el tráfico de salida                     |       |
| **db**              | Ingress   | SG: app               | TCP       | 3306      | Permitir MySQL desde capa App                          |       |
| db                  | Ingress   | SG: break_glass       | TCP       | 3306      | Permitir MySQL desde Break Glass server                |       |
| **ssm**             | Ingress   | SG: app               | TCP       | 443       | Permitir HTTPS desde capa App                          |       |
| ssm                 | Ingress   | SG: web               | TCP       | 443       | Permitir HTTPS desde capa Web                          |       |
| ssm                 | Ingress   | SG: break_glass       | TCP       | 443       | Permitir HTTPS desde Break Glass server                |       |
| ssm                 | Egress    | 0.0.0.0/0             | ALL       | ALL       | Permitir todo el tráfico de salida                     |       |
| **secrets_manager** | Ingress   | SG: app               | TCP       | 443       | Permitir HTTPS desde capa App                          |       |
| secrets_manager     | Ingress   | SG: break_glass       | TCP       | 443       | Permitir HTTPS desde Break Glass server                |       |
| secrets_manager     | Egress    | 0.0.0.0/0             | ALL       | ALL       | Permitir todo el tráfico de salida                     |       |
| **break_glass**     | Ingress   | CIDR: var.on-prem-vpn | TCP       | 22        | Permitir SSH desde On-Prem VPN                         |       |
| break_glass         | Egress    | CIDR: var.on-prem-vpn | ALL       | ALL       | Permitir salida hacia On-Prem VPN                      |       |
<p><em>(Tabla 4 – Grupos de Seguridad)</em></p>
</div>

Tres VPC endpoints permiten la comunicación segura con AWS Systems Manager para las capas Web y App, lo que garantiza que todo el tráfico que pasa por el Session Manager permanezca interno. Otro VPC endpoint para AWS Secrets Manager permite que la capa App interactúe con el servicio de forma segura.

Una distribución de CloudFront almacena en caché la capa Web, evitando que exista comunicación directa entre el usuario y la capa Web. La distribución está protegida por WAF con las siguientes reglas:

<div align="center">

| Prioridad | Nombre de la regla                   | Tipo               | Acción                        | Descripción                                                                           |
| --------- | ------------------------------------ | ------------------ | ----------------------------- | ------------------------------------------------------------------------------------- |
| 1         | AWSManagedRulesCommonRuleSet          | Managed Rule Group | Predeterminado                | Protecciones básicas contra amenazas comunes                                          |
| 2         | RateLimitPerIP                        | Rate-Based Rule    | Bloquear                      | Bloquea IPs que excedan 800 solicitudes durante 5 minutos (protección contra DDoS/fuerza bruta) |
| 3         | AWSManagedRulesSQLiRuleSet            | Managed Rule Group | Predeterminado                | Detecta intentos de inyección SQL                                                     |
| 4         | AWSManagedRulesAmazonIpReputationList | Managed Rule Group | Predeterminado                | Detecta/bloquea solicitudes desde IPs maliciosas conocidas (aws threat intelligence) |

<p><em>(Tabla 5 – Reglas WAF)</em></p>
</div>

Una instancia Break-glass en EC2 proporciona acceso de emergencia a todos nuestros servidores en las capas Web y App, así como a los VPC endpoints, en el caso de una falla inesperada de SSM Session Manager o una mala configuración. La instancia permite tráfico de entrada en el puerto 22 (SSH) únicamente desde el rango de direcciones IP de la VPN on-premise.


## 6. Identidad y Acceso. 

La solución requiere tres roles, los cuales permiten que las instancias EC2 en los tiers Web/App puedan interactuar con los servicios SSM Session Manager and Secrets Manager (solo capa App), y otro rol que permite que EventBridge publique eventos a SNS. 

<div align="center">

| Nombre del rol                  | Servicio de confianza  | Políticas adjuntas                                                                                                          | Propósito                                                                        |
| -------------------------------- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| ssm_role                         | ec2.amazonaws.com      | AmazonSSMManagedInstanceCore                                                                                                 | Permite que las instancias EC2 usen AWS Systems Manager (SSM).                   |
| ssm-secrets-manager              | ec2.amazonaws.com      | AmazonSSMManagedInstanceCore, política personalizada (secretsmanager:GetSecretValue, secretsmanager:DescribeSecret en el secreto de la BD) | Permite que la capa App de EC2 use SSM y obtenga secretos de BD desde Secrets Manager. |
| eventbridge_guardduty_sns_role   | events.amazonaws.com   | Política inline (sns:Publish en el tema sns_guardduty_finding)                                                               | Permite que EventBridge publique los hallazgos de GuardDuty en un SNS topic.      |

<p><em>(Tabla 6 – Roles)</em></p>
</div>

Se usa AWS Secrets Manager para guardar las credenciales de la base de datos, las cuales serán usadas por la App. Un VPC Endpoint garantiza que el tráfico desde la App hacia el servicio se haga de forma privada (tráfico dentro de AWS).

## 7. Login y Cumplimiento

**IAM Access Analyzer:** Usado para análisis de acceso, revisión y generación de políticas. Se habilitó análisis External y Unused para la solución, lo cual permite identificar acceso a nuestros recursos y permisos que no estén siendo usados, esto ayudará a ajustar el principio de menor privilegio. 

**AWS Cloudtrail:** Registra las llamadas a las APIs realizadas en la cuenta y las guarda en un bucket de S3

**AWS Config:** Registra toda la configuración y los cambios de configuración de nuestros recursos y también guarda la información en su propio bucket de S3.

**VPC Flow Logs:** Registra todo el tráfico dentro de nuestra VPC, lo cual se puede usar para resolución de problemas.

**Amazon Inspector:** Escanea nuestras instancias EC2 (de nuestros dos Auto Scaling Groups en las capas Web/App) en busca de vulnerabilidades conocidas.

**Amazon Detective:** Un servicio de investigación forense y análisis que nos ayuda a entender el contexto y la causa raíz de una actividad sospechosa detectada.

## 8. Monitoreo y Respuesta

**CloudWatch Metrics:** Se crean cuatro métricas de CloudWatch junto al despliegue del recurso WAF, y nos permitirán seguir las reglas Managed y Rate-based del WAF (como se describe en la sección de Network Security).

**GuardDuty findings:** Está configurado para notificarnos por correo electrónico sobre hallazgos CRÍTICOS, integrándose con EventBridge y SNS.

**Security Hub:** Provee una vista centralizada de hallazgos de seguridad y cumplimiento que nos permitirá generar dashboards de cumplimiento para marcos de seguridad tales como CIS, PCI DSS, NIST o integrar sistemas SIEM como Splunk.

## 9. AWS Well-Achitected Framework

La solución la diseñé siguiendo el Well-Achitected Framework de AWS de mejores prácticas. El framework se basa en seis pilares resumidos a continuación (pilar "sostenibilidad" no está incluido): 

<div align="center">

![AWS Well-Architected Framework](README/well-architected.png)
<p><em>(img. 2 – Pilares del AWS Well-Architected Framework)</em></p>
</div>

En la tabla 6 he mapeado cómo cada servicio y decisión de arquitectura de esta solución encaja en cada pilar:

<div align="center">

| Pilar                        | Prácticas / Controles Clave                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Excelencia Operacional** | - Infrastructure as Code (Terraform): despliegues repetibles y auditables<br>- CloudWatch alarms y políticas de escalado: monitoreo proactivo de la salud del sistema<br>- Notificaciones automáticas por correo electrónico para hallazgos de GuardDuty<br>- Instancia Break-glass: respaldo operacional para respuesta a incidentes                                                                                                                                                                                                                                                                            |
| **Seguridad**               | - Segmentación de red: arquitectura de 3 capas con subnets privadas para Web/App/DB<br>- Grupos de seguridad con privilegio mínimo: reglas de ingreso/egreso granulares por capa<br>- Gestión de identidad: IAM roles, instance profiles, políticas IAM personalizadas<br>- Secrets Manager: sin credenciales de BD hardcodeadas, con versionado<br>- VPC Endpoints: acceso privado a SSM & Secrets Manager<br>- Detección y monitoreo: CloudTrail, Config, GuardDuty, Inspector, Detective, Security Hub<br>- Protección perimetral: CloudFront + WAF + ACM para TLS<br>- Logging y auditoría: VPC Flow Logs, CloudTrail logs |
| **Confiabilidad**            | - Subnets en múltiples AZs: alta disponibilidad entre zonas<br>- ASGs con políticas de escalado: auto-recuperación + escalado basado en demanda<br>- Dos ALBs (capas web + app): puntos de entrada redundantes<br>- Route53: DNS administrado con health checks<br>- NAT Gateways en múltiples AZs: acceso de salida resiliente                                                                                                                                                                                                                                                                                                              |
| **Eficiencia de Rendimiento** | - Auto Scaling: escala las capas web/app bajo demanda<br>- CloudFront CDN: mejora la latencia al cachear contenido cerca de los usuarios<br>- Separación de capas: permite escalado independiente (web vs. app vs. DB)                                                                                                                                                                                                                                                                                                                                                                                                      |
| **Optimización de Costos**      | - Políticas de Auto Scaling: previenen sobreaprovisionamiento<br>- VPC Endpoints: reducen costos de procesamiento de datos en NAT Gateway<br>- Flow logs y logging centralizado en S3: almacenamiento rentable a largo plazo<br>- Nombres aleatorios para buckets: evita colisiones de recursos y reutiliza infraestructura de manera eficiente                                                                                                                                                                                                                                                                                                                 |
| **Sostenibilidad**         | - Auto Scaling + right-sizing: evita ejecución de recursos inactivos<br>- CloudFront caching: reduce llamadas repetitivas al backend, bajando uso de recursos<br>- Separación de entornos: permite activar/desactivar la infraestructura según necesidad                                                                                                                                                                                                                                                                                                                                                                               |

<p><em>(Tabla 6 – Implementación del Marco Well-Architected de AWS)</em></p>
</div>

## 10. Conclusión

Este proyecto demuestra un diseño de seguridad de defensa en profundidad y bien arquitectado para una aplicación de 3 capas en AWS, implementado completamente con Terraform. Al integrar segmentación de red, principio de privilegio mínimo en IAM, gestión de secretos, logging, detección de anomalías y protección perimetral, la arquitectura es resiliente, segura y alineada con las mejores prácticas de AWS
