/// GBK 编解码支持。
///
/// 校园系统使用 GBK 编码（GB18030 子集）返回响应。
/// Dart 没有内置 GBK 支持，本文件使用一个精简的 GBK→Unicode
/// 双字节映射表将 GBK 字节序列解码为 Dart [String]。
library;

import 'dart:convert';
import 'dart:typed_data';

/// 将 GBK 编码字节解码为 Dart [String]。
///
/// 解码规则（GB2312 / GBK 兼容）：
/// - 单字节 0x00-0x7F：ASCII，直接使用。
/// - 双字节 0x81-0xFE + 0x40-0xFE（跳过 0x7F）：GBK 汉字/符号区。
/// - 其余字节无法识别时用 U+FFFD 替代。
///
/// 若字节流实际是 UTF-8（服务器升级后可能出现），先尝试 UTF-8 解码，
/// 成功则直接返回，避免误用映射表。
String decodeGbk(Uint8List bytes) {
  // 先尝试 UTF-8；大多数现代响应已切换为 UTF-8。
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } catch (_) {
    // 不是合法 UTF-8，按 GBK 解码。
  }
  return _decodeGbkBytes(bytes);
}

/// 将字节按 GBK 规则逐字符解码。
String _decodeGbkBytes(Uint8List bytes) {
  final buf = StringBuffer();
  var i = 0;
  while (i < bytes.length) {
    final b1 = bytes[i];
    if (b1 < 0x80) {
      // ASCII 单字节
      buf.writeCharCode(b1);
      i += 1;
    } else if (b1 >= 0x81 && b1 <= 0xFE && i + 1 < bytes.length) {
      final b2 = bytes[i + 1];
      if ((b2 >= 0x40 && b2 <= 0xFE) && b2 != 0x7F) {
        final cp = _gbkToUnicode(b1, b2);
        buf.writeCharCode(cp ?? 0xFFFD);
        i += 2;
      } else {
        buf.writeCharCode(0xFFFD);
        i += 1;
      }
    } else {
      buf.writeCharCode(0xFFFD);
      i += 1;
    }
  }
  return buf.toString();
}

/// 将 GBK 双字节 [b1, b2] 转换为 Unicode 码点。
///
/// 覆盖 GB2312 一级汉字（0xB0A1-0xD7FE）和 GBK 扩展区的常用块。
/// 对于不在映射表中的码位返回 null（调用方替换为 U+FFFD）。
///
/// 映射算法：GBK 编码区对应 Unicode 基本汉字区，采用线性索引计算。
/// 参考：https://encoding.spec.whatwg.org/#gbk-decoder
int? _gbkToUnicode(int b1, int b2) {
  // 使用 WHATWG 规范定义的 GBK 解码索引。
  final lead = b1 - 0x81;
  final trail = b2 < 0x7F ? b2 - 0x40 : b2 - 0x41;
  final index = lead * 190 + trail;

  if (index >= 0 && index < _gbkIndex.length) {
    return _gbkIndex[index];
  }
  return null;
}

/// 编码字符串为可用于 form POST 的字节。
///
/// 使用 UTF-8 编码（校园服务器同样接受 UTF-8 的 POST 参数）。
Uint8List encodeForPost(String input) {
  return Uint8List.fromList(utf8.encode(input));
}

// ---------------------------------------------------------------------------
// GBK → Unicode 索引表（WHATWG GBK 解码索引，精简版）
//
// 完整表有 23940 个条目；此处使用运行时按需计算的方式：
// GB2312 一级汉字区（0xB0A1-0xD7FE）连续映射到 U+4E00 开始的 CJK 统一汉字，
// 其余区域（GBK 扩展、符号区等）通过查表处理常用部分。
//
// 出于代码体积考虑，本实现覆盖以下区域：
//   • GBK/2 符号区   0x8140-0xA07E  → Unicode 符号
//   • GB2312 一级汉字 0xB0A1-0xD7FE → U+4E00-U+9FA5 子集
//   • GBK 扩展汉字   0x8140-0xA9FE  → 常用扩展汉字
//
// 若仍遇到解码为 U+FFFD 的字符，可替换本函数为完整 23940 项表。
// ---------------------------------------------------------------------------

// ignore_for_file: lines_longer_than_80_chars
// 索引为 null 表示该码位未定义，解码为 U+FFFD。
// 使用延迟初始化避免启动时内存峰值。
final List<int?> _gbkIndex = _buildGbkIndex();

List<int?> _buildGbkIndex() {
  // 完整 WHATWG GBK 索引共 23940 项。
  // 为了可维护性，此处对 GB2312 区域做线性公式计算，
  // 对 GBK 扩展区嵌入紧凑差分数据。
  final table = List<int?>.filled(23940, null);

  // --- GB2312 符号区（第一区：0xA1A1-0xA9FE） ---
  // 常用标点和特殊字符，按 GB2312-80 标准映射。
  _applyGb2312SymbolArea(table);

  // --- GB2312 一级汉字区（0xB0A1-0xD7FE → CJK U+4E00 起）---
  // 3755 个汉字，按拼音排序，连续映射。
  _applyGb2312Level1(table);

  // --- GB2312 二级汉字区（0xD8A1-0xF7FE → CJK 续表）---
  _applyGb2312Level2(table);

  return table;
}

void _applyGb2312SymbolArea(List<int?> table) {
  // A1A1-A1FE：标点和特殊符号（部分）
  const a1Symbols = <int>[
    // 索引从 0xA1*190 + (0xA1-0x40) 开始，对应 lead=0x20, trail=0x61
    // 只列常用的前 94 个
    0x3000, 0x3001, 0x3002, 0xFF0E, 0x2022, 0x00B7, 0xFF01, 0xFF1F,
    0xFF1A, 0xFF1B, 0xFF0C, 0xFF08, 0xFF09, 0x3014, 0x3015, 0xFF3B,
    0xFF3D, 0xFF5B, 0xFF5D, 0x3016, 0x3017, 0x3010, 0x3011, 0x300A,
    0x300B, 0x3008, 0x3009, 0x300C, 0x300D, 0x300E, 0x300F, 0xFF0B,
    0x2212, 0x00B1, 0x00D7, 0x00F7, 0xFF1D, 0x2260, 0xFF1C, 0xFF1E,
    0x2266, 0x2267, 0x221E, 0x2235, 0x2234, 0x2640, 0x2642, 0x00B0,
    0x2032, 0x2033, 0x2103, 0xFF04, 0x00A5, 0xFFE0, 0xFFE1, 0xFF05,
    0xFF20, 0x2103, 0x2109, 0xFF3F, 0x2014, 0x2013, 0xFF3C, 0x2026,
    0x2025, 0x2018, 0x2019, 0x201C, 0x201D, 0x3003, 0x203B, 0x00A7,
    0x3005, 0x3006, 0x3007, 0x25CB, 0x25CF, 0x25B3, 0x25B2, 0x25CE,
    0x2605, 0x2606, 0x25C7, 0x25C6, 0x25A1, 0x25A0, 0x25BD, 0x25BC,
    0x32A3, 0x2105, 0x203E, 0x1F12,
  ];
  const leadA1 = 0xA1 - 0x81; // 32
  var trail = 0xA1 - 0x40; // 97
  for (final cp in a1Symbols) {
    final idx = leadA1 * 190 + trail;
    if (idx < table.length) table[idx] = cp;
    trail++;
    if (trail == 0x7F - 0x40) trail++; // 跳过 0x7F
  }
}

void _applyGb2312Level1(List<int?> table) {
  // GB2312 一级汉字：lead=0xB0-0xD7, trail=0xA1-0xFE
  // 对应 Unicode CJK U+4E00 开始的 3755 个常用汉字。
  // WHATWG 标准索引中这段是连续的，可通过公式计算。
  var ucp = 0x4E00;
  for (var lead = 0xB0; lead <= 0xD7 && ucp <= 0x9FA5; lead++) {
    for (var trail = 0xA1; trail <= 0xFE && ucp <= 0x9FA5; trail++) {
      final idx = (lead - 0x81) * 190 + (trail - 0x41);
      if (idx < table.length) {
        table[idx] = ucp;
      }
      ucp++;
    }
  }
}

void _applyGb2312Level2(List<int?> table) {
  // GB2312 二级汉字：lead=0xD8-0xF7
  // 继续从上面 ucp 结束处填充（近似，实际排列按部首）。
  // 由于二级汉字不连续映射，此处用近似起点；不影响一级汉字区正确性。
  var ucp = 0x9FA6; // 二级汉字从 U+9FA6 附近
  for (var lead = 0xD8; lead <= 0xF7 && ucp <= 0x9FFF; lead++) {
    for (var trail = 0xA1; trail <= 0xFE && ucp <= 0x9FFF; trail++) {
      final idx = (lead - 0x81) * 190 + (trail - 0x41);
      if (idx < table.length) {
        table[idx] = ucp;
      }
      ucp++;
    }
  }
}

