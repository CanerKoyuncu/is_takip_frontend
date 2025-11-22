import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'API_KEY')
  static final String apiKey = "EYMPc0WHwH6dSALXdpopBo3NaP6WL4d64WtLegnZ";
}
