import 'package:flutter/material.dart';

class AppSkeleton extends StatefulWidget {
  final Widget child;
  final Duration period;

  const AppSkeleton({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1300),
  });

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final slide = (_controller.value * 2) - 1;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.15, 0.5, 0.85],
              begin: Alignment(-1.5 + slide, -0.25),
              end: Alignment(1.5 + slide, 0.25),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
    );
  }
}

class ServicesListSkeleton extends StatelessWidget {
  final int itemCount;

  const ServicesListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(height: 18),
                            SizedBox(height: 10),
                            SkeletonBox(width: 90, height: 20),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      SkeletonBox(width: 52, height: 24),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      SkeletonBox(width: 120, height: 14),
                      Spacer(),
                      SkeletonBox(width: 90, height: 32),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CartListSkeleton extends StatelessWidget {
  final int itemCount;

  const CartListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SkeletonBox(width: 48, height: 48),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: 16),
                              SizedBox(height: 8),
                              SkeletonBox(width: 70, height: 12),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        SkeletonBox(width: 24, height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SkeletonBox(width: 50, height: 14),
                      Spacer(),
                      SkeletonBox(width: 90, height: 20),
                    ],
                  ),
                  SizedBox(height: 16),
                  SkeletonBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingsListSkeleton extends StatelessWidget {
  final int itemCount;

  const BookingsListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 16)),
                      SizedBox(width: 16),
                      SkeletonBox(width: 70, height: 18),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      SkeletonBox(width: 90, height: 20),
                      Spacer(),
                      SkeletonBox(width: 70, height: 14),
                    ],
                  ),
                  SizedBox(height: 16),
                  SkeletonBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CheckoutSkeleton extends StatelessWidget {
  const CheckoutSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: const Column(
          children: [
            SizedBox(height: 8),
            SkeletonBox(width: 80, height: 80),
            SizedBox(height: 20),
            SkeletonBox(height: 140),
            SizedBox(height: 20),
            SkeletonBox(height: 56),
            SizedBox(height: 16),
            SkeletonBox(height: 56),
            SizedBox(height: 16),
            SkeletonBox(height: 56),
            SizedBox(height: 16),
            SkeletonBox(height: 56),
            SizedBox(height: 16),
            SkeletonBox(height: 56),
            SizedBox(height: 16),
            SkeletonBox(height: 56),
            SizedBox(height: 16),
            SkeletonBox(height: 56),
            SizedBox(height: 22),
            SkeletonBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class SlotsSkeleton extends StatelessWidget {
  const SlotsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppSkeleton(
      child: Column(
        children: [
          SkeletonBox(height: 16),
          SizedBox(height: 10),
          SkeletonBox(height: 16),
          SizedBox(height: 10),
          SkeletonBox(height: 16),
        ],
      ),
    );
  }
}
