class YiffComics extends ComicSource {
    name = "Yiff Comics";
    key = "yiff_comics";
    version = "1.1.0";
    minAppVersion = "1.0.0";
    url = "";

    baseUrl = "https://yiff-comics.com";

    // 1. Explore / Latest Feed
    explore = [
        {
            title: "Latest",
            type: "multiPageComicList",
            load: async (page) => {
                let url = page === 1 ? this.baseUrl : `${this.baseUrl}/?page=${page}`;
                let res = await Network.get(url, { "User-Agent": "Mozilla/5.0" });
                if (res.status !== 200) throw `HTTP Error: ${res.status}`;

                return this.parseComicList(res.body);
            }
        }
    ];

    // 2. Categories & Filters
    category = {
        title: "Categories",
        parts: [
            {
                name: "Orientation",
                type: "fixed",
                categories: ["Straight", "Gay", "Lesbian", "Futa", "Trans"],
                itemType: "category",
                categoryParams: [
                    "orientation/straight",
                    "orientation/gay",
                    "orientation/lesbian",
                    "orientation/futa",
                    "orientation/trans"
                ]
            },
            {
                name: "Popular Genres",
                type: "fixed",
                categories: [
                    "Anthro", "Feral", "Anal", "Blowjob", "Yaoi", 
                    "Muscle", "Vaginal", "Big Penis", "Canine", 
                    "Dragon", "Fox", "Wolf", "Pony"
                ],
                itemType: "category",
                categoryParams: [
                    "genre/anthro", "genre/feral", "genre/anal", "genre/blowjob", "genre/yaoi",
                    "genre/muscle", "genre/vaginal", "genre/big-penis", "genre/canine",
                    "genre/dragon", "genre/fox", "genre/wolf", "genre/pony"
                ]
            },
            {
                name: "Featured Artists",
                type: "fixed",
                categories: [
                    "Amadose", "Jay Naylor", "Mortarionlordofdeath", "Matemi", 
                    "Zourik", "Cuchuflin", "Twang", "Wolfanine", "Baileyx"
                ],
                itemType: "category",
                categoryParams: [
                    "artist/amadose", "artist/jay-naylor", "artist/mortarionlordofdeath", "artist/matemi",
                    "artist/zourik", "artist/cuchuflin", "artist/twang", "artist/wolfanine", "artist/baileyx"
                ]
            }
        ],
        enableRankingPage: false
    };

    // Category Comic Loader
    categoryComics = {
        load: async (category, param, options, page) => {
            let url = page === 1 
                ? `${this.baseUrl}/${param}/` 
                : `${this.baseUrl}/${param}/?page=${page}`;

            let res = await Network.get(url, { "User-Agent": "Mozilla/5.0" });
            if (res.status !== 200) throw `HTTP Error: ${res.status}`;

            return this.parseComicList(res.body);
        }
    };

    // 3. Search
    search = {
        load: async (keyword, options, page) => {
            let query = encodeURIComponent(keyword);
            let url = page === 1 
                ? `${this.baseUrl}/search/?q=${query}` 
                : `${this.baseUrl}/search/?q=${query}&page=${page}`;

            let res = await Network.get(url, { "User-Agent": "Mozilla/5.0" });
            if (res.status !== 200) throw `HTTP Error: ${res.status}`;

            return this.parseComicList(res.body);
        }
    };

    // Helper: Parse comic list from HTML
    parseComicList(html) {
        let comics = [];
        // Match comic links: href="/yiff/<slug>/"
        let regex = /href="\/yiff\/([^\/"]+)\/"/g;
        let match;
        let seen = new Set();

        while ((match = regex.exec(html)) !== null) {
            let slug = match[1];
            if (seen.has(slug)) continue;
            seen.add(slug);

            // Clean title from slug
            let title = slug.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
            comics.push({
                id: slug,
                title: title,
                subTitle: "",
                cover: `https://cdn.yiff-comics.com/posts/${slug}/cover-card.webp`,
                tags: [],
                description: ""
            });
        }

        return {
            comics: comics,
            maxPage: 100
        };
    }

    // 4. Comic Details & Reader
    comic = {
        loadInfo: async (id) => {
            let url = `${this.baseUrl}/yiff/${id}/`;
            let res = await Network.get(url, { "User-Agent": "Mozilla/5.0" });
            if (res.status !== 200) throw `HTTP Error: ${res.status}`;

            let html = res.body;

            // Extract Title from <title> tag
            let titleMatch = html.match(/<title>([^<]+)<\/title>/);
            let rawTitle = titleMatch ? titleMatch[1] : id;
            let title = rawTitle.replace(/\s*▷\s*YIFF COMICS.*/i, '').trim();

            // Extract Cover Image
            let coverMatch = html.match(/https:\/\/cdn\.yiff-comics\.com\/posts\/[^"'\s\\]+\/cover\.webp/);
            let cover = coverMatch ? coverMatch[0] : "";

            // Extract total pages count (e.g. "1 / 7")
            let pageCountMatch = html.match(/(\d+)\s*(?:<!-- -->)?\s*\/\s*(?:<!-- -->)?\s*(\d+)/);
            let totalPages = pageCountMatch ? parseInt(pageCountMatch[2], 10) : 1;

            // Extract first page url to determine base directory on CDN
            let firstPageMatch = html.match(/(https:\/\/cdn\.yiff-comics\.com\/posts\/[^"'\s\\]+\/)p001\.webp/);
            let cdnBase = firstPageMatch ? firstPageMatch[1] : "";

            // Single episode/chapter containing all pages
            let chapters = new Map();
            chapters.set(`${totalPages}|${cdnBase}`, "Chapter 1");

            return {
                title: title,
                cover: cover,
                description: `Total pages: ${totalPages}`,
                tags: { "Tags": ["Furry", "NSFW"] },
                chapters: chapters
            };
        },

        loadEp: async (comicId, epId) => {
            let [pageCountStr, cdnBase] = epId.split("|");
            let count = parseInt(pageCountStr, 10) || 1;
            let images = [];

            // Generate sequential page URLs (p001.webp, p002.webp, ...)
            for (let i = 1; i <= count; i++) {
                let pageNum = String(i).padStart(3, '0');
                if (cdnBase) {
                    images.push(`${cdnBase}p${pageNum}.webp`);
                }
            }

            return {
                images: images
            };
        },

        // Provide anti-hotlink referer headers
        onImageLoad: (url, comicId, epId) => {
            return {
                headers: {
                    "Referer": "https://yiff-comics.com/",
                    "User-Agent": "Mozilla/5.0"
                }
            };
        }
    };
}
