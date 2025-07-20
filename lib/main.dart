import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isForgot = false;
  String message = "";

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    confirmPassController.clear();
    usernameController.clear();
    phoneController.clear();
    otpController.clear();
  }

  Future<void> register() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPass = confirmPassController.text.trim();

    if ([username, email, phone, password, confirmPass].any((e) => e.isEmpty)) {
      setState(() => message = "⚠️ Fill all fields");
      return;
    }

    if (password != confirmPass) {
      setState(() => message = "⚠️ Passwords don't match");
      return;
    }

    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(username)
        .get();

    if (existingUser.exists) {
      setState(() => message = "❌ Username already taken");
      return;
    }

    try {
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance.collection('users').doc(username).set({
        'email': email,
        'phone': phone,
        'password': password,
      });

      clearFields();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(username: username),
        ),
      );
    } catch (e) {
      setState(() => message = "❌ ${e.toString()}");
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => message = "⚠️ Fill all fields");
      return;
    }

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      String username = userSnapshot.docs.isNotEmpty
          ? userSnapshot.docs.first.id
          : "User";

      clearFields();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(username: username),
        ),
      );
    } catch (e) {
      setState(() => message = "❌ ${e.toString()}");
    }
  }

  Future<void> forgotPassword() async {
    final phone = phoneController.text.trim();
    final otp = otpController.text.trim();

    if (phone.isEmpty) {
      setState(() => message = "⚠️ Enter registered phone number");
      return;
    }

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    if (userSnapshot.docs.isEmpty) {
      setState(() => message = "❌ No user found with this phone");
      return;
    }

    String username = userSnapshot.docs.first.id;
    String password = userSnapshot.docs.first['password'];

    if (otp.isEmpty) {
      setState(() => message = "📩 OTP sent to your email (Use: 123456)");
    } else if (otp == "123456") {
      setState(() => message = "✅ Username: $username\nPassword: $password");
    } else {
      setState(() => message = "❌ Invalid OTP");
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user!;
      final username = user.email!.split('@')[0];

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .get();

      if (!doc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(username)
            .set({
          'email': user.email,
          'phone': '',
          'password': '',
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => DashboardPage(username: username)),
      );
    } catch (e) {
      setState(() => message = "❌ apki  aukat nhi");
    }
  }

  InputDecoration customInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Text(
                'Instagram',
                style: GoogleFonts.lobster(
                    color: Colors.white, fontSize: 40),
              ),
            ),
            const SizedBox(height: 40),
            if (!isLogin && !isForgot)
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: customInput("Username"),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: isForgot ? phoneController : emailController,
              style: const TextStyle(color: Colors.white),
              decoration: customInput(
                  isForgot ? "Phone number" : "Email address"),
            ),
            const SizedBox(height: 12),
            if (!isForgot)
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: customInput("Password"),
              ),
            if (!isLogin && !isForgot)
              const SizedBox(height: 12),
            if (!isLogin && !isForgot)
              TextField(
                controller: confirmPassController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: customInput("Confirm Password"),
              ),
            if (!isLogin && !isForgot)
              const SizedBox(height: 12),
            if (!isLogin && !isForgot)
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                decoration: customInput("Phone Number"),
              ),
            if (isForgot)
              const SizedBox(height: 12),
            if (isForgot)
              TextField(
                controller: otpController,
                style: const TextStyle(color: Colors.white),
                decoration: customInput("Enter OTP (123456)"),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => isForgot
                  ? forgotPassword()
                  : (isLogin ? login() : register()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(isForgot
                  ? "Recover Password"
                  : (isLogin ? "Log In" : "Register")),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isForgot = !isForgot;
                  isLogin = true;
                  message = "";
                  clearFields();
                });
              },
              child: Text(isForgot
                  ? "← Back to Login"
                  : "Forgotten password?",
                  style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                  isForgot = false;
                  message = "";
                  clearFields();
                });
              },
              child: Text(
                isLogin
                    ? "Don't have an account? Sign Up"
                    : "Already have an account? Log In",
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text("Log in with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.blue,
                shadowColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}









// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'dashboard.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AuthScreen(),
//     );
//   }
// }
//
// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen> {
//   bool isLogin = true;
//   bool isForgot = false;
//   String message = "";
//
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPassController = TextEditingController();
//   final usernameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final otpController = TextEditingController();
//
//   void clearFields() {
//     emailController.clear();
//     passwordController.clear();
//     confirmPassController.clear();
//     usernameController.clear();
//     phoneController.clear();
//     otpController.clear();
//   }
//
//   Future<void> register() async {
//     final username = usernameController.text.trim();
//     final email = emailController.text.trim();
//     final phone = phoneController.text.trim();
//     final password = passwordController.text.trim();
//     final confirmPass = confirmPassController.text.trim();
//
//     if ([username, email, phone, password, confirmPass].any((e) => e.isEmpty)) {
//       setState(() => message = "⚠️ Fill all fields");
//       return;
//     }
//
//     if (password != confirmPass) {
//       setState(() => message = "⚠️ Passwords don't match");
//       return;
//     }
//
//     try {
//       final userCred = await FirebaseAuth.instance
//           .createUserWithEmailAndPassword(email: email, password: password);
//
//       await FirebaseFirestore.instance.collection('users').doc(username).set({
//         'email': email,
//         'phone': phone,
//         'password': password,
//       });
//
//       clearFields();
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => DashboardScreen(username: username),
//         ),
//       );
//     } catch (e) {
//       setState(() => message = "❌ ${e.toString()}");
//     }
//   }
//
//   Future<void> login() async {
//     final email = emailController.text.trim();
//     final password = passwordController.text.trim();
//
//     if (email.isEmpty || password.isEmpty) {
//       setState(() => message = "⚠️ Fill all fields");
//       return;
//     }
//
//     try {
//       await FirebaseAuth.instance
//           .signInWithEmailAndPassword(email: email, password: password);
//
//       final userSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .where('email', isEqualTo: email)
//           .get();
//
//       String username = userSnapshot.docs.isNotEmpty
//           ? userSnapshot.docs.first.id
//           : "User";
//
//       clearFields();
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => DashboardScreen(username: username),
//         ),
//       );
//     } catch (e) {
//       setState(() => message = "❌ ${e.toString()}");
//     }
//   }
//
//   Future<void> forgotPassword() async {
//     final phone = phoneController.text.trim();
//     final otp = otpController.text.trim();
//
//     if (phone.isEmpty) {
//       setState(() => message = "⚠️ Enter registered phone number");
//       return;
//     }
//
//     final userSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .where('phone', isEqualTo: phone)
//         .get();
//
//     if (userSnapshot.docs.isEmpty) {
//       setState(() => message = "❌ No user found with this phone");
//       return;
//     }
//
//     String username = userSnapshot.docs.first.id;
//     String password = userSnapshot.docs.first['password'];
//
//     if (otp.isEmpty) {
//       setState(() => message = "📩 OTP sent to your email (Use: 123456)");
//     } else if (otp == "123456") {
//       setState(() => message = "✅ Username: $username\nPassword: $password");
//     } else {
//       setState(() => message = "❌ Invalid OTP");
//     }
//   }
//
//   Future<void> signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) return;
//
//       final GoogleSignInAuthentication googleAuth =
//       await googleUser.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       UserCredential userCred =
//       await FirebaseAuth.instance.signInWithCredential(credential);
//       final user = userCred.user!;
//       final username = user.email!.split('@')[0];
//
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(username)
//           .get();
//
//       if (!doc.exists) {
//         await FirebaseFirestore.instance
//             .collection('users')
//             .doc(username)
//             .set({
//           'email': user.email,
//           'phone': '',
//           'password': '',
//         });
//       }
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (_) => DashboardScreen(username: username)),
//       );
//     } catch (e) {
//       setState(() => message = "❌ Hello  $usernameController ");
//     }
//   }
//
//   InputDecoration customInput(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(color: Colors.grey),
//       filled: true,
//       fillColor: const Color(0xFF1E1E1E),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: ListView(
//           children: [
//             const SizedBox(height: 80),
//             Center(
//               child: Text(
//                 'Instagram',
//                 style: GoogleFonts.lobster(
//                     color: Colors.white, fontSize: 40),
//               ),
//             ),
//             const SizedBox(height: 40),
//             if (!isLogin && !isForgot)
//               TextField(
//                 controller: usernameController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: customInput("Username"),
//               ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: isForgot ? phoneController : emailController,
//               style: const TextStyle(color: Colors.white),
//               decoration: customInput(
//                   isForgot ? "Phone number" : "Email address"),
//             ),
//             const SizedBox(height: 12),
//             if (!isForgot)
//               TextField(
//                 controller: passwordController,
//                 obscureText: true,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: customInput("Password"),
//               ),
//             if (!isLogin && !isForgot)
//               const SizedBox(height: 12),
//             if (!isLogin && !isForgot)
//               TextField(
//                 controller: confirmPassController,
//                 obscureText: true,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: customInput("Confirm Password"),
//               ),
//             if (!isLogin && !isForgot)
//               const SizedBox(height: 12),
//             if (!isLogin && !isForgot)
//               TextField(
//                 controller: phoneController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: customInput("Phone Number"),
//               ),
//             if (isForgot)
//               const SizedBox(height: 12),
//             if (isForgot)
//               TextField(
//                 controller: otpController,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: customInput("Enter OTP (123456)"),
//               ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => isForgot
//                   ? forgotPassword()
//                   : (isLogin ? login() : register()),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 minimumSize: const Size(double.infinity, 48),
//               ),
//               child: Text(isForgot
//                   ? "Recover Password"
//                   : (isLogin ? "Log In" : "Register")),
//             ),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   isForgot = !isForgot;
//                   isLogin = true;
//                   message = "";
//                   clearFields();
//                 });
//               },
//               child: Text(isForgot
//                   ? "← Back to Login"
//                   : "Forgotten password?",
//                   style: const TextStyle(color: Colors.grey)),
//             ),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   isLogin = !isLogin;
//                   isForgot = false;
//                   message = "";
//                   clearFields();
//                 });
//               },
//               child: Text(
//                 isLogin
//                     ? "Don't have an account? Sign Up"
//                     : "Already have an account? Log In",
//                 style: const TextStyle(color: Colors.grey),
//               ),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton.icon(
//               onPressed: signInWithGoogle,
//               icon: const Icon(Icons.g_mobiledata),
//               label: const Text("Log in with Google"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 foregroundColor: Colors.blue,
//                 shadowColor: Colors.transparent,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Center(
//               child: Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     color: Colors.red, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
