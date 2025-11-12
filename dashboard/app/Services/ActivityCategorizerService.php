<?php

namespace App\Services;

class ActivityCategorizerService
{
    const CATEGORY_WORK = 'work';
    const CATEGORY_SOCIAL = 'social_media';
    const CATEGORY_SUSPICIOUS = 'suspicious';

    /**
     * Work-related keywords
     */
    protected $workKeywords = [
        // Office Apps
        'excel', 'xls', 'xlsx', 'spreadsheet',
        'word', 'doc', 'docx', 'document',
        'powerpoint', 'ppt', 'pptx', 'presentation',
        'pdf', 'adobe', 'acrobat',

        // Accounting/Finance
        'accurate', 'coretax', 'pajak.go.id', 'e-faktur', 'efaktur',
        'e-spt', 'espt', 'jurnal.id', 'zahir', 'myob',
        'accounting', 'finance', 'akuntansi', 'keuangan',

        // Email
        'mail.google.com', 'gmail', 'outlook', 'office.com',
        'email', 'inbox', 'webmail',

        // Productivity Tools
        'drive.google.com', 'docs.google.com', 'sheets.google.com',
        'dropbox', 'onedrive', 'notion', 'trello', 'asana',

        // Communication (work)
        'slack', 'teams', 'zoom', 'meet.google.com',
        'skype', 'webex',

        // Development (if applicable)
        'github', 'gitlab', 'bitbucket', 'stackoverflow',
        'localhost', 'dev.', 'staging.', 'admin.',
    ];

    /**
     * Social media & entertainment keywords
     */
    protected $socialKeywords = [
        // Social Media
        'youtube', 'youtu.be', 'instagram', 'tiktok',
        'facebook', 'fb.com', 'twitter', 'x.com',
        'whatsapp.com', 'telegram.org', 'linkedin.com',

        // Entertainment
        'netflix', 'disney', 'hbo', 'spotify',
        'soundcloud', 'twitch', 'reddit',

        // Shopping
        'tokopedia', 'shopee', 'lazada', 'bukalapak',
        'amazon', 'ebay', 'alibaba', 'olx', 'carousell',

        // News/Portal (non-work)
        'detik.com', 'kompas.com', 'tribun',
        'liputan6', 'cnnindonesia',
    ];

    /**
     * Suspicious keywords (gambling, gaming, etc)
     */
    protected $suspiciousKeywords = [
        // Gambling/Betting
        'judi', 'taruhan', 'betting', 'bet', 'odds',
        'slot', 'casino', 'poker', 'roulette', 'blackjack',
        'sbobet', 'maxbet', 'togel', 'jackpot',
        'deposit', 'withdraw', 'bonus slot', 'gacor',

        // Online Gaming
        'mobile legends', 'mobilelegends', 'ml.', 'mlbb',
        'free fire', 'freefire', 'garena',
        'pubg', 'fortnite', 'valorant', 'apex legends',
        'steam', 'epicgames', 'battle.net',
        'roblox', 'minecraft', 'genshin', 'honkai',
        'mobile legend', 'game online',
    ];

    /**
     * Categorize a URL activity
     *
     * @param string $url
     * @param string $domain
     * @param string|null $pageTitle
     * @return string 'work', 'social_media', or 'suspicious'
     */
    public function categorize(string $url, string $domain, ?string $pageTitle = null): string
    {
        // Combine all text for searching
        $searchText = strtolower($url . ' ' . $domain . ' ' . ($pageTitle ?? ''));

        // 1. Check SUSPICIOUS first (highest priority)
        foreach ($this->suspiciousKeywords as $keyword) {
            if ($this->containsKeyword($searchText, $keyword)) {
                return self::CATEGORY_SUSPICIOUS;
            }
        }

        // 2. Check WORK keywords
        foreach ($this->workKeywords as $keyword) {
            if ($this->containsKeyword($searchText, $keyword)) {
                return self::CATEGORY_WORK;
            }
        }

        // 3. Check SOCIAL MEDIA keywords
        foreach ($this->socialKeywords as $keyword) {
            if ($this->containsKeyword($searchText, $keyword)) {
                return self::CATEGORY_SOCIAL;
            }
        }

        // Default: work (benefit of the doubt)
        return self::CATEGORY_WORK;
    }

    /**
     * Check if text contains keyword (word boundary aware)
     *
     * @param string $text
     * @param string $keyword
     * @return bool
     */
    protected function containsKeyword(string $text, string $keyword): bool
    {
        // Use strpos for basic matching
        // For more accuracy, can use word boundaries with regex
        return strpos($text, strtolower($keyword)) !== false;
    }

    /**
     * Batch categorize multiple activities
     *
     * @param array $activities Array of ['url' => '', 'domain' => '', 'page_title' => '']
     * @return array Array with added 'category' key
     */
    public function batchCategorize(array $activities): array
    {
        return array_map(function ($activity) {
            $activity['category'] = $this->categorize(
                $activity['url'] ?? '',
                $activity['domain'] ?? '',
                $activity['page_title'] ?? null
            );
            return $activity;
        }, $activities);
    }

    /**
     * Get category label (for display)
     *
     * @param string $category
     * @return string
     */
    public function getCategoryLabel(string $category): string
    {
        return match($category) {
            self::CATEGORY_WORK => 'Pekerjaan',
            self::CATEGORY_SOCIAL => 'Media Sosial',
            self::CATEGORY_SUSPICIOUS => 'Tidak Teridentifikasi',
            default => 'Pekerjaan',
        };
    }

    /**
     * Get category color (for Excel/UI)
     *
     * @param string $category
     * @return string Hex color code
     */
    public function getCategoryColor(string $category): string
    {
        return match($category) {
            self::CATEGORY_WORK => '70AD47',        // Green
            self::CATEGORY_SOCIAL => 'FFC000',      // Orange/Yellow
            self::CATEGORY_SUSPICIOUS => 'FF0000',  // Red
            default => '70AD47',
        };
    }

    /**
     * Get category icon (emoji)
     *
     * @param string $category
     * @return string
     */
    public function getCategoryIcon(string $category): string
    {
        return match($category) {
            self::CATEGORY_WORK => '🟢',
            self::CATEGORY_SOCIAL => '🔴',
            self::CATEGORY_SUSPICIOUS => '⚫',
            default => '🟢',
        };
    }
}