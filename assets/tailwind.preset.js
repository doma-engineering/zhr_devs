const colors = {
  purple: {
    DEFAULT: '#9747ff',
  },
  "light-green": {
    DEFAULT: '#EDFFDB',
    dark: "#D4F9B0"
  },
  gray: {
    light: "#F5F5F5",
    DEFAULT: '#DCDCDC',
    dark: "#CACACA",
    code: "#2D2D2D",
  },
  "light-blue": {
    DEFAULT: "#DCEDF7",
  },
  white: "#ffffff",
  black: "#000000",
}

module.exports = {
  important: true,
  theme: {
    screens: {
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1536px',
      'toc': "1337px",
    },
    fontSize: {
      sm: ['1rem', '1.46'],
      base: ['1.125rem', '1.50'],
      lg: ['1.357rem','1.245'],
      xl: ['2.125rem', '1.159'],
      '2xl': ['2.5rem', '1.159'],
      '3xl': ['3.375rem', '1.114'],
      // --- Modifications -------
      'base-auto': ['1.125rem', 'auto'],
      'base-thin': ['1.125rem', '1.15'],
      // --- Mobile exceptions ---
      'm_2xl': ['2.357rem', '1.114'],
      'm_xl': ['1.625rem', '1.159'],
      'm_sm': ['1rem', '1.159'],
    },
    fontFamily: {
      sans: ['koyak-sans', 'sans-serif'],
      mono: ['ubuntu-mono', 'doma-archia-mono'],
    },
    extend: {
      spacing: {
        '135': '33.75rem', // 540 px 
        'sidenotes': '258px',
        'articles': '666px',
        'm_articles': '683px',
        'text-container': '776px',
        'code-container': '736px',
        'toc-height': '600px',
        'calendly-height': "700px",
        'm-calendly-height': '1200px',
      }
    },
    wider: {
      center: true,
      padding: "1rem",
      screens: {
        lg: "1200px",
        xl: "1300px",
        "2xl": "1800px",
      },
    },
    container: {
      center: true,
      padding: "1rem",
      screens: {
        lg: "1124px",
        xl: "1124px",
        "2xl": "1124px",
      },
    },
    borderRadius: {
      'none': '0',
      'sm': '0.125rem',
      'md': '0.375rem',
      DEFAULT: '10px',
      'lg': '0.5rem',
      'full': '9999px',
      'large': '12px',
    },
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      ...colors,
      "accent-background": colors["light-green"].DEFAULT,
      "accent-foreground": colors.black,
      "functional-background": colors.purple.DEFAULT,
      "functional-foreground": colors.white,
      "functional-passive": colors.gray.DEFAULT,
      "functional-disabled": colors.gray.dark,
      "functional-inverted-background": colors["light-green"].DEFAULT,
      "functional-inverted-foreground": colors.purple.DEFAULT,
      "functional-inverted-active": colors["light-green"].dark,
      "professional-background": colors["light-blue"].DEFAULT,
      "professional-foreground": colors.black,
      "content-background": colors.white,
      "content-foreground": colors.black,
      "code-background": colors.gray.code,
      "code-foreground": colors.white,
      "calendar-background": colors.gray.light,
      "calendar-foreground": colors.purple.DEFAULT,
      "calendar-label": colors.black,
      "calendar-label-accent": colors.purple.DEFAULT,
      "calendar-disabled": colors.gray.dark,
    },
  },
  variants: {
    extend: {
      padding: ['hover'],
    },
  },
  plugins: []
};