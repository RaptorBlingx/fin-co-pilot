import 'package:flutter/material.dart';
import 'animated_button.dart';

/// Beautiful onboarding carousel with smooth page transitions
///
/// Features:
/// - Smooth page animations
/// - Interactive indicators
/// - Skip and Next buttons
/// - Auto-scroll option
/// - Customizable pages
class OnboardingCarousel extends StatefulWidget {
  final List<OnboardingPage> pages;
  final VoidCallback onComplete;
  final bool showSkipButton;
  final bool autoScroll;
  final Duration autoScrollDuration;

  const OnboardingCarousel({
    super.key,
    required this.pages,
    required this.onComplete,
    this.showSkipButton = true,
    this.autoScroll = false,
    this.autoScrollDuration = const Duration(seconds: 4),
  });

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // Auto scroll if enabled
    if (widget.autoScroll) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.delayed(widget.autoScrollDuration, () {
      if (mounted && _currentPage < widget.pages.length - 1) {
        _nextPage();
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skipOnboarding() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (widget.showSkipButton && _currentPage < widget.pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Skip'),
                  ),
                ),
              )
            else
              const SizedBox(height: 64),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _fadeController.reset();
                  _fadeController.forward();
                },
                itemCount: widget.pages.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildPage(widget.pages[index]),
                  );
                },
              ),
            ),

            // Page indicators
            _buildPageIndicators(),

            const SizedBox(height: 32),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedButton(
                label: _currentPage == widget.pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
                isFullWidth: true,
                icon: _currentPage == widget.pages.length - 1
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Transform.rotate(
                  angle: (1 - value) * 0.2,
                  child: page.illustration,
                ),
              );
            },
          ),

          const SizedBox(height: 64),

          // Title
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Text(
                    page.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Description
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Text(
                    page.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentPage == index ? 32 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Onboarding page model
class OnboardingPage {
  final String title;
  final String description;
  final Widget illustration;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

/// Predefined onboarding pages for FinCoPilot
class FinCoPilotOnboarding {
  static List<OnboardingPage> getPages(BuildContext context) {
    return [
      // Page 1: SMS Auto-Parsing
      OnboardingPage(
        title: 'Auto-Track Every Transaction',
        description: '80% of your spending tracked automatically from bank SMS. Zero manual entry required.',
        illustration: _buildIllustration(
          context,
          Icons.sms_rounded,
          Colors.blue,
        ),
      ),

      // Page 2: Voice Entry
      OnboardingPage(
        title: 'Just Speak, We\'ll Track',
        description: 'Add transactions by voice in seconds. "Coffee at Starbucks, \$5.50" - done!',
        illustration: _buildIllustration(
          context,
          Icons.mic_rounded,
          Colors.purple,
        ),
      ),

      // Page 3: Financial Health Score
      OnboardingPage(
        title: 'Your Financial Health Score',
        description: 'Track your financial wellness with a simple 0-100 score. Watch it improve over time!',
        illustration: _buildIllustration(
          context,
          Icons.favorite_rounded,
          Colors.red,
        ),
      ),

      // Page 4: Smart Nudges
      OnboardingPage(
        title: 'Proactive Alerts',
        description: 'Get timely nudges before you overspend. We\'ll help you stay on budget.',
        illustration: _buildIllustration(
          context,
          Icons.notifications_active_rounded,
          Colors.orange,
        ),
      ),

      // Page 5: Daily Money Story
      OnboardingPage(
        title: 'Your Daily Money Story',
        description: 'Get a beautiful summary of your day\'s spending at 9 PM. Know exactly where your money went.',
        illustration: _buildIllustration(
          context,
          Icons.auto_stories_rounded,
          Colors.teal,
        ),
      ),

      // Page 6: Couples Dashboard
      OnboardingPage(
        title: 'Manage Finances Together',
        description: 'Share budgets with your partner. Track spending together. No more money arguments.',
        illustration: _buildIllustration(
          context,
          Icons.favorite_border_rounded,
          Colors.pink,
        ),
      ),
    ];
  }

  static Widget _buildIllustration(
    BuildContext context,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 100,
          color: color,
        ),
      ),
    );
  }
}

/// Animated dotted progress indicator
class DottedProgressIndicator extends StatefulWidget {
  final int currentPage;
  final int pageCount;
  final Color activeColor;
  final Color inactiveColor;

  const DottedProgressIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<DottedProgressIndicator> createState() =>
      _DottedProgressIndicatorState();
}

class _DottedProgressIndicatorState extends State<DottedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void didUpdateWidget(DottedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pageCount, (index) {
        final isActive = index == widget.currentPage;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final animatedValue = isActive
                ? Curves.easeOut.transform(_controller.value)
                : 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 32 * animatedValue : 8,
              decoration: BoxDecoration(
                color: isActive ? widget.activeColor : widget.inactiveColor,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}
