import 'package:flutter/material.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/screens/rooms_screen.dart'; // Importa RoomsScreen para la navegación

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _message = '';

  // Función para manejar el registro de usuarios
  Future<void> _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Por favor, ingrese usuario y contraseña.';
      });
      return;
    }

    setState(() {
      _message = 'Registrando...';
    });

    final result = await _apiService.registerUser(username, password);

    setState(() {
      if (result['success']) {
        _message = 'Registro exitoso: ${result['data']['username']}';
        _usernameController.clear(); // Limpia los campos después de un registro exitoso
        _passwordController.clear();
      } else {
        _message = 'Fallo el registro: ${result['message']}';
      }
    });
  }

  // Función para manejar el inicio de sesión de usuarios
  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Por favor, ingrese usuario y contraseña.';
      });
      return;
    }

    setState(() {
      _message = 'Iniciando sesión...';
    });

    final result = await _apiService.loginUser(username, password);

    setState(() {
      if (result['success']) {
        _message = 'Inicio de sesión exitoso para: ${result['data']['username']}';
        // Navega a la pantalla de salas y reemplaza la ruta actual
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoomsScreen(loggedInUsername: username), // Pasa el nombre de usuario
          ),
        );
      } else {
        _message = 'Fallo el inicio de sesión: ${result['message']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro como en el diseño
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0), // Más padding horizontal
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar elementos horizontalmente
          children: <Widget>[
            // Logo de la aplicación
            // Nota: El logo 'studyroom.jpg' es verde. Para que coincida con el diseño blanco,
            // la imagen debería ser una versión en blanco o un SVG que pueda ser recoloreado.
            // Por ahora, solo se ajusta el tamaño.
            Image.asset(
              'assets/images/studyroom.jpg',
              height: 120, // Altura ajustada
              width: 120,
              fit: BoxFit.contain,
              // color: Colors.white, // Descomentar si el logo es SVG y quieres colorearlo de blanco
              // colorBlendMode: BlendMode.srcIn, // Descomentar si el logo es SVG y quieres colorearlo de blanco
            ),
            const SizedBox(height: 50), // Espacio después del logo

            // Etiqueta "Correo electrónico"
            const Text(
              'Correo electrónico',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Campo de texto para el nombre de usuario
            TextField(
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white), // Texto de entrada blanco
              decoration: const InputDecoration(
                hintText: 'tu@ejemplo.com', // Texto de ayuda
                hintStyle: TextStyle(color: Colors.white54), // Color del hint
                enabledBorder: UnderlineInputBorder( // Borde inferior normal
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder( // Borde inferior cuando está en foco
                  borderSide: BorderSide(color: Colors.white),
                ),
                prefixIcon: Icon(Icons.person, color: Colors.white70), // Icono blanco
              ),
            ),
            const SizedBox(height: 20),

            // Etiqueta "Contraseña"
            const Text(
              'Contraseña',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Campo de texto para la contraseña
            TextField(
              controller: _passwordController,
              obscureText: true, // Oculta la contraseña
              style: const TextStyle(color: Colors.white), // Texto de entrada blanco
              decoration: const InputDecoration(
                hintText: '********', // Texto de ayuda
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                prefixIcon: Icon(Icons.lock, color: Colors.white70), // Icono blanco
              ),
            ),
            const SizedBox(height: 40), // Espacio antes del botón de login

            // Botón de iniciar sesión
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Fondo blanco
                foregroundColor: Colors.black, // Texto negro
                padding: const EdgeInsets.symmetric(vertical: 18), // Más padding vertical
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Bordes muy redondeados
                ),
                elevation: 5, // Sombra
              ),
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Mensaje de estado (éxito/error)
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('exitoso') ? Colors.greenAccent : Colors.redAccent, // Colores para mensajes
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Texto "¿No tienes cuenta? Regístrate"
            GestureDetector(
              onTap: _register, // Llama a la función de registro al tocar
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: '¿No tienes cuenta? ',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Regístrate',
                      style: TextStyle(
                        color: Colors.white, // "Regístrate" en blanco
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline, // Subrayado
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
