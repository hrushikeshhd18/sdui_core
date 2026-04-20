import 'package:flutter/material.dart';

import 'package:sdui_core/src/utils/sdui_logger.dart';

/// Maps snake_case icon name strings to Flutter [IconData] values.
///
/// ```dart
/// Icon(SduiIcons.fromName('shopping_cart'))
/// Icon(SduiIcons.fromName('mystery_icon', fallback: Icons.error))
/// ```
abstract final class SduiIcons {
  /// Returns the [IconData] for [name], or [fallback] if not found.
  ///
  /// Falls back to [Icons.help_outline] when both [name] and [fallback]
  /// are missing.
  static IconData fromName(String name, {IconData? fallback}) {
    final icon = _icons[name];
    if (icon == null) {
      SduiLogger.warn('SduiIcons: unknown icon name "$name"');
    }
    return icon ?? fallback ?? Icons.help_outline;
  }

  static const Map<String, IconData> _icons = {
    // Navigation
    'home': Icons.home,
    'search': Icons.search,
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,
    'arrow_upward': Icons.arrow_upward,
    'arrow_downward': Icons.arrow_downward,
    'chevron_right': Icons.chevron_right,
    'chevron_left': Icons.chevron_left,
    'expand_more': Icons.expand_more,
    'expand_less': Icons.expand_less,
    'menu': Icons.menu,
    'close': Icons.close,
    'more_vert': Icons.more_vert,
    'more_horiz': Icons.more_horiz,

    // Actions
    'add': Icons.add,
    'remove': Icons.remove,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'share': Icons.share,
    'copy': Icons.copy,
    'download': Icons.download,
    'upload': Icons.upload,
    'refresh': Icons.refresh,
    'save': Icons.save,
    'send': Icons.send,
    'filter': Icons.filter_list,
    'sort': Icons.sort,
    'tune': Icons.tune,

    // Status
    'check': Icons.check,
    'check_circle': Icons.check_circle,
    'error': Icons.error,
    'error_outline': Icons.error_outline,
    'warning': Icons.warning,
    'warning_amber': Icons.warning_amber,
    'info': Icons.info,
    'info_outline': Icons.info_outline,
    'help': Icons.help_outline,
    'cancel': Icons.cancel,

    // Person & account
    'person': Icons.person,
    'person_add': Icons.person_add,
    'group': Icons.group,
    'account_circle': Icons.account_circle,
    'settings': Icons.settings,
    'lock': Icons.lock,
    'unlock': Icons.lock_open,
    'lock_open': Icons.lock_open,
    'visibility': Icons.visibility,
    'visibility_off': Icons.visibility_off,

    // Communication
    'phone': Icons.phone,
    'email': Icons.email,
    'chat': Icons.chat,
    'notifications': Icons.notifications,
    'notifications_none': Icons.notifications_none,
    'notifications_off': Icons.notifications_off,

    // Media
    'camera': Icons.camera_alt,
    'photo': Icons.photo,
    'image': Icons.image,
    'video': Icons.videocam,
    'mic': Icons.mic,
    'mic_off': Icons.mic_off,
    'volume_up': Icons.volume_up,
    'volume_off': Icons.volume_off,
    'play': Icons.play_arrow,
    'pause': Icons.pause,
    'stop': Icons.stop,
    'skip_next': Icons.skip_next,
    'skip_previous': Icons.skip_previous,

    // Shopping & commerce
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'store': Icons.store,
    'storefront': Icons.storefront,
    'payment': Icons.payment,
    'credit_card': Icons.credit_card,
    'card': Icons.credit_card,
    'wallet': Icons.account_balance_wallet,
    'receipt': Icons.receipt,
    'discount': Icons.discount,
    'percent': Icons.percent,
    'local_offer': Icons.local_offer,
    'loyalty': Icons.loyalty,

    // Favorites & ratings
    'favorite': Icons.favorite,
    'favorite_border': Icons.favorite_border,
    'star': Icons.star,
    'star_border': Icons.star_border,
    'star_half': Icons.star_half,
    'bookmark': Icons.bookmark,
    'bookmark_border': Icons.bookmark_border,

    // Location & maps
    'location_on': Icons.location_on,
    'location': Icons.location_on,
    'location_off': Icons.location_off,
    'map': Icons.map,
    'directions': Icons.directions,
    'delivery': Icons.local_shipping,
    'local_shipping': Icons.local_shipping,
    'navigation': Icons.navigation,

    // Time
    'calendar': Icons.calendar_today,
    'calendar_today': Icons.calendar_today,
    'clock': Icons.access_time,
    'access_time': Icons.access_time,
    'timer': Icons.timer,
    'schedule': Icons.schedule,

    // Files & data
    'folder': Icons.folder,
    'file': Icons.insert_drive_file,
    'attach_file': Icons.attach_file,
    'link': Icons.link,
    'qr_code': Icons.qr_code,
    'barcode': Icons.barcode_reader,

    // Misc UI
    'dark_mode': Icons.dark_mode,
    'light_mode': Icons.light_mode,
    'brightness': Icons.brightness_6,
    'language': Icons.language,
    'translate': Icons.translate,
    'accessibility': Icons.accessibility,
    'flash_on': Icons.flash_on,
    'flash_off': Icons.flash_off,
    'wifi': Icons.wifi,
    'wifi_off': Icons.wifi_off,
    'bluetooth': Icons.bluetooth,
    'battery': Icons.battery_full,
  };
}
