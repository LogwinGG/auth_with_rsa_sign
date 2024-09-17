// 1) Сгенерировать саму пару ĸлючей: приватного и публичного.
// 2) Запрос № 2 “Отправĸа публичного ĸлюча на сервер”
// 3) Запрос № 1 “Авторизация на сервере”

import 'dart:convert';
import 'dart:math';

import 'package:asn1lib/asn1lib.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart' as pointy;

import 'package:dio/dio.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:uuid/uuid.dart';


final dio = Dio();
const uuid =  Uuid();

class AuthService  {

  Future<String?> signInWithApple() async {
    try {
      Response response1;
      Response response2;
      String udid = await FlutterUdid.consistentUdid.then((v)=> v.substring(0,40));

      String rnd = uuid.v4();
      String login = 'loginTest';
      final keyPair = generateKeyPair();
      String pmk = encodePublicKeyToPem(keyPair.publicKey);
      RSAPrivateKey privateKey = keyPair.privateKey;

      Uint8List hashUdidRnd = sha1Digest(utf8.encode(udid+rnd));  // строĸа из ĸонĸатенации udid+rnd хешируется алгоритмом SHA1
      final signature2 = rsaSign(privateKey, hashUdidRnd); // полученное значение подписывается приватным ĸлючом
      // Запрос2
      final formData2 = FormData.fromMap(
          {
            "oper": "init",
            "udid": udid,
            "rnd" : rnd,
            "pmk" : base64.encode(utf8.encode(pmk)) ,
            "signature": base64.encode( signature2 ),
            "fcm_key": "x"
          }
      );
      response2 = await dio.post('https://vp-line.aysec.org/ios.php', data: formData2);

      Uint8List hashUdidRndLogin = sha1Digest(utf8.encode(udid+rnd+login)); //строĸа из ĸонĸатенации udid+rnd+login хешируется алгоритмом SHA1
      final signature1 = rsaSign( privateKey, hashUdidRndLogin); //полученное значение подписывается приватным ĸлючом

      //Запрос1
      final formData1 = FormData.fromMap({
        "udid": udid,
        "email": "emailTest@ya.ru",
        "login": login,
        "oper": "login_apple_id",
        "rnd" : rnd,
        "signature": base64.encode( signature1 )
      });
      response1 = await dio.post( 'https://vp-line.aysec.org/ios.php', data: formData1);

      return response1.data['work_status']['udid'];

    } on DioException catch (e) {
      if (kDebugMode) {
        if (e.response != null) {
          print(e.response!.data);
          print(e.response!.headers);
          print(e.response!.requestOptions);
        } else {
          // Something happened in setting up or sending the request that triggered an Error
          print(e.requestOptions);
          print(e.message);
        }
      }
    }
    return null;
  }

  AsymmetricKeyPair<pointy.RSAPublicKey, pointy.RSAPrivateKey> generateKeyPair() {
    var keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 12);

    var secureRandom = FortunaRandom();
    var random =  Random.secure();
    List<int> seeds = [];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    secureRandom.seed( KeyParameter( Uint8List.fromList(seeds)));

    var rngParams =  ParametersWithRandom(keyParams, secureRandom);
    var k =  RSAKeyGenerator();
    k.init(rngParams);
    AsymmetricKeyPair keyPair = k.generateKeyPair();
    AsymmetricKeyPair<pointy.RSAPublicKey, pointy.RSAPrivateKey> pair =
    AsymmetricKeyPair(keyPair.publicKey as pointy.RSAPublicKey,
        keyPair.privateKey as pointy.RSAPrivateKey);
    return pair;
  }

  encodePublicKeyToPem(RSAPublicKey publicKey) {
    var algorithmSeq = ASN1Sequence();
    var algorithmAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1]));
    var paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    var publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    var publicKeySeqBitString = ASN1BitString(Uint8List.fromList(publicKeySeq.encodedBytes));

    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);

    return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
  }

  Uint8List sha1Digest(Uint8List dataToDigest) {
    final d = SHA1Digest();
    return d.process(dataToDigest);
  }

  Uint8List rsaSign(RSAPrivateKey privateKey, Uint8List dataToSign) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');

    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final sig = signer.generateSignature(dataToSign);

    return sig.bytes;
  }

}
