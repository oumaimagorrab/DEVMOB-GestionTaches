import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      minHeight: size.height * 0.6,
                    ),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B5BD6).withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: -10,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 🔵 Logo animé avec effet de pulsation
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _AnimatedLogo(),
                        ),

                        const SizedBox(height: 32),

                        // 📝 Titre avec dégradé
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF5B5BD6), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            "Bienvenue",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 📄 Description améliorée
                        Text(
                          "Gérez vos projets et collaborez efficacement avec votre équipe en temps réel.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ✨ Points forts (valeurs ajoutées)
                        _FeatureRow(
                          icon: Icons.people_outline,
                          text: "Collaboration en équipe",
                          delay: 400,
                        ),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          icon: Icons.insights_outlined,
                          text: "Suivi de projets avancé",
                          delay: 500,
                        ),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          icon: Icons.security_outlined,
                          text: "Sécurité entreprise",
                          delay: 600,
                        ),

                        const SizedBox(height: 40),

                        // 🔘 Bouton Se connecter avec effet de vague
                        _AnimatedButton(
                          text: "Se connecter",
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/login');
                          },
                          isPrimary: true,
                        ),

                        const SizedBox(height: 16),

                        // 🔘 Bouton S'inscrire
                        _AnimatedButton(
                          text: "S'inscrire",
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(context, '/register');
                          },
                          isPrimary: false,
                        ),

                        const SizedBox(height: 24),

                        // 🔗 Lien "Continuer en tant qu'invité"
                        TextButton(
                          onPressed: () {
                            // Navigation invité
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade500,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            "Continuer en tant qu'invité →",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 Logo animé avec effet de pulsation subtile
class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B5BD6).withOpacity(
                  0.2 + (_pulseController.value * 0.1),
                ),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: 2 + (_pulseController.value * 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercle de fond avec dégradé
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B5BD6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B5BD6).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              // Badge éclair positionné
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ✨ Widget pour les fonctionnalités avec animation staggered
class _FeatureRow extends StatefulWidget {
  final IconData icon;
  final String text;
  final int delay;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.delay,
  });

  @override
  State<_FeatureRow> createState() => _FeatureRowState();
}

class _FeatureRowState extends State<_FeatureRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF5B5BD6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: const Color(0xFF5B5BD6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔘 Bouton animé avec effet de vague et feedback haptique
class _AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _AnimatedButton({
    required this.text,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final button = widget.isPrimary
        ? ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5BD6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: const Color(0xFF5B5BD6).withOpacity(0.4),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          )
        : OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5B5BD6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF5B5BD6), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                const Color(0xFF5B5BD6).withOpacity(0.1),
              ),
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: button,
      ),
    );
  }
}