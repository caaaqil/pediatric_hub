import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_dimens.dart';
import '../../../data/models/misc.dart';
import '../../../data/static/education_content.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/HealthEducation.jsx`.
///
/// The web page keeps its 40 Somali articles hardcoded in the component and
/// never calls `GET /education`, so mobile ships the same content from
/// `data/static/education_content.dart`. Anything an administrator publishes
/// through `POST /education` is appended below it, so both sources show.
class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  static const String _all = 'Dhammaan';
  String _category = _all;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final AsyncValue<List<EducationalContent>> published = ref.watch(
      articlesProvider,
    );

    final List<String> categories = <String>[
      _all,
      ...<String>{for (final EduArticle a in kEduArticles) a.category},
    ];

    final List<EduArticle> visible = _category == _all
        ? kEduArticles
        : kEduArticles
              .where((EduArticle a) => a.category == _category)
              .toList();

    final EduArticle featured = kEduArticles.firstWhere(
      (EduArticle a) => a.featured,
      orElse: () => kEduArticles.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Health Education')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('⭐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Maqaalada Muuqda',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FeaturedCard(article: featured),
          const SizedBox(height: 20),

          // Category pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((String c) {
                final bool selected = c == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _category = c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.violet : palette.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? AppColors.violet : palette.border,
                        ),
                      ),
                      child: Text(
                        c.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: selected
                              ? Colors.white
                              : palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Nutrition guide
          Row(
            children: <Widget>[
              const Text('🌿', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                'Hagaha Nafaqada',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            // Tall enough for the image, two description lines and the bar.
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kEduNutrition.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int i) =>
                  _NutritionCard(item: kEduNutrition[i]),
            ),
          ),
          const SizedBox(height: 24),

          // Article list
          Text(
            _category == _all ? 'Dhammaan Maqaalada' : _category,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...visible.map(
            (EduArticle a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ArticleTile(article: a),
            ),
          ),

          // Anything an admin published through the API
          published.maybeWhen(
            data: (List<EducationalContent> items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Published by administrators',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (EducationalContent c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PublishedTile(content: c),
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),
          _TipsCard(),
        ],
      ),
    );
  }
}

/// The large hero article card at the top of the page.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.article});

  final EduArticle article;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext ctx) => ArticleDetailScreen(article: article),
        ),
      ),
      borderRadius: AppRadius.lgAll,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFFBE123C)),
                loadingBuilder:
                    (BuildContext c, Widget child, ImageChunkEvent? progress) =>
                        progress == null
                        ? child
                        : Container(color: const Color(0xFFBE123C)),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      const Color(0xFFBE123C).withValues(alpha: 0.95),
                      const Color(0xFFBE123C).withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        article.readTime,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        article.views,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Akhri',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.item});

  final EduNutrition item;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SizedBox(
      width: 210,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 82,
              width: double.infinity,
              child: Image.network(
                item.img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: palette.surfaceSoft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: item.pct / 100,
                      minHeight: 5,
                      backgroundColor: palette.surfaceSoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.pct}% Lagugu Taliyay',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.article});

  final EduArticle article;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext ctx) => ArticleDetailScreen(article: article),
        ),
      ),
      borderRadius: AppRadius.mdAll,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: palette.border),
          boxShadow: AppShadows.sm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 96,
              height: 96,
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: palette.surfaceSoft),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      article.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: AppColors.violet,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.readTime,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.visibility_outlined,
                          size: 11,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.views,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
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

class _PublishedTile extends StatelessWidget {
  const _PublishedTile({required this.content});

  final EducationalContent content;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            content.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            content.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'TALOOYIN DEGDEG AH',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...kEduTips.map(
            (String tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('•  '),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full article reader — renders every section heading and body.
class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.article});

  final EduArticle article;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(article.category)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: <Widget>[
          ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                article.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: palette.surfaceSoft),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.25,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            article.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(Icons.schedule_rounded, size: 13, color: palette.textMuted),
              const SizedBox(width: 5),
              Text(
                article.readTime,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.visibility_outlined,
                size: 13,
                color: palette.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                article.views,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            ],
          ),
          const Divider(height: 36),
          ...article.sections.map(
            (EduSection s) => Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.heading,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.65),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
