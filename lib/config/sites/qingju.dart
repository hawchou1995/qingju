import '../site_customization.dart';

/// 青橘仅使用标准 Discourse 能力，不加载其他社区的专属插件。
const qingjuCustomization = SiteCustomization(
  linkSecurityConfig: LinkSecurityConfig(
    enableExitConfirmation: true,
    internalDomains: ['qingju.me'],
  ),
);
