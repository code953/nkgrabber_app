/// 校园响应的文本解码。
///
/// 服务器目前发的是 UTF-8——2026-08-28 的实测截图里，短响应逐字正确，只有被
/// 截断的长响应才乱码（成因在调用方，见 `_CampusLoggingInterceptor`）。GBK
/// 分支保留为兜底：这套部署的其余部分处处透着 GB 时代的痕迹，换回去不是不可能。
///
/// 兜底用 `charset` 包，不再用手写映射表。原先那张表按公式生成，
/// `_applyGb2312Level1` 假设 GB2312 一级汉字线性映射到 U+4E00（实际按拼音排序），
/// `_applyGb2312Level2` 的注释里自己写着"近似"。实测 `趣味足球` 会解成
/// `囓夙岔囃`——它不报错，而是编出看着像汉字的错字，这比解码失败更难发现。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:charset/charset.dart';

/// 将响应字节解码为 Dart [String]。
///
/// 先按 UTF-8 严格解码；失败才按 GBK 解。顺序不能反：GBK 几乎能"解"出任何
/// 字节序列，先试 GBK 就等于放弃了区分。
String decodeGbk(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    // 不是合法 UTF-8，按 GBK 解码。
  }
  try {
    return gbk.decode(bytes);
  } on Object {
    // 两种编码都解不动：宁可显示替换字符，也不要凭空造字。
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// 编码字符串为可用于 form POST 的字节。
///
/// 使用 UTF-8 编码（校园服务器同样接受 UTF-8 的 POST 参数）。
Uint8List encodeForPost(String input) {
  return Uint8List.fromList(utf8.encode(input));
}
