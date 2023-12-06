/// A translation of `linux/kd.h`
module sily.terminal.linux.kd;

/* 0x4B is 'K', to avoid collision with termios and vt */

enum GIO_FONT = 0x4B60; /* gets font in expanded form */
enum PIO_FONT = 0x4B61; /* use font in expanded form */

enum GIO_FONTX = 0x4B6B; /* get font using struct consolefontdesc */
enum PIO_FONTX = 0x4B6C; /* set font using struct consolefontdesc */
struct consolefontdesc {
    ushort charcount; /* characters in font (256 or 512) */
    ushort charheight; /* scan lines per character (1-32) */
    char* chardata; /* font data in expanded form */
}

enum PIO_FONTRESET = 0x4B6D; /* reset to default font */

enum GIO_CMAP = 0x4B70; /* gets colour palette on VGA+ */
enum PIO_CMAP = 0x4B71; /* sets colour palette on VGA+ */

enum KIOCSOUND = 0x4B2F; /* start sound generation (0 for off) */
enum KDMKTONE = 0x4B30; /* generate tone */

enum KDGETLED = 0x4B31; /* return current led state */
enum KDSETLED = 0x4B32; /* set led state [lights, not flags] */
enum LED_SCR = 0x01; /* scroll lock led */
enum LED_NUM = 0x02; /* num lock led */
enum LED_CAP = 0x04; /* caps lock led */

enum KDGKBTYPE = 0x4B33; /* get keyboard type */
enum KB_84 = 0x01;
enum KB_101 = 0x02; /* this is what we always answer */
enum KB_OTHER = 0x03;

enum KDADDIO = 0x4B34; /* add i/o port as valid */
enum KDDELIO = 0x4B35; /* del i/o port as valid */
enum KDENABIO = 0x4B36; /* enable i/o to video board */
enum KDDISABIO = 0x4B37; /* disable i/o to video board */

enum KDSETMODE = 0x4B3A; /* set text/graphics mode */
enum KD_TEXT = 0x00;
enum KD_GRAPHICS = 0x01;
enum KD_TEXT0 = 0x02; /* obsolete */
enum KD_TEXT1 = 0x03; /* obsolete */
enum KDGETMODE = 0x4B3B; /* get current mode */

enum KDMAPDISP = 0x4B3C; /* map display into address space */
enum KDUNMAPDISP = 0x4B3D; /* unmap display from address space */

alias scrnmap_t = char;
enum E_TABSZ = 256;
enum GIO_SCRNMAP = 0x4B40; /* get screen mapping from kernel */
enum PIO_SCRNMAP = 0x4B41; /* put screen mapping table in kernel */
enum GIO_UNISCRNMAP = 0x4B69; /* get full Unicode screen mapping */
enum PIO_UNISCRNMAP = 0x4B6A; /* set full Unicode screen mapping */

enum GIO_UNIMAP = 0x4B66; /* get unicode-to-font mapping from kernel */
struct unipair {
    ushort unicode;
    ushort fontpos;
};
struct unimapdesc {
    ushort entry_ct;
    unipair* entries;
};
enum PIO_UNIMAP = 0x4B67; /* put unicode-to-font mapping in kernel */
enum PIO_UNIMAPCLR = 0x4B68; /* clear table, possibly advise hash algorithm */
struct unimapinit {
    ushort advised_hashsize; /* 0 if no opinion */
    ushort advised_hashstep; /* 0 if no opinion */
    ushort advised_hashlevel; /* 0 if no opinion */
};

enum UNI_DIRECT_BASE = 0xF000; /* start of Direct Font Region */
enum UNI_DIRECT_MASK = 0x01FF; /* Direct Font Region bitmask */

enum K_RAW = 0x00;
enum K_XLATE = 0x01;
enum K_MEDIUMRAW = 0x02;
enum K_UNICODE = 0x03;
enum K_OFF = 0x04;
enum KDGKBMODE = 0x4B44; /* gets current keyboard mode */
enum KDSKBMODE = 0x4B45; /* sets current keyboard mode */

enum K_METABIT = 0x03;
enum K_ESCPREFIX = 0x04;
enum KDGKBMETA = 0x4B62; /* gets meta key handling mode */
enum KDSKBMETA = 0x4B63; /* sets meta key handling mode */

enum K_SCROLLLOCK = 0x01;
enum K_NUMLOCK = 0x02;
enum K_CAPSLOCK = 0x04;
enum KDGKBLED = 0x4B64; /* get led flags (not lights) */
enum KDSKBLED = 0x4B65; /* set led flags (not lights) */

struct kbentry {
    char kb_table;
    char kb_index;
    ushort kb_value;
}
enum K_NORMTAB = 0x00;
enum K_SHIFTTAB = 0x01;
enum K_ALTTAB = 0x02;
enum K_ALTSHIFTTAB = 0x03;

enum KDGKBENT = 0x4B46; /* gets one entry in translation table */
enum KDSKBENT = 0x4B47; /* sets one entry in translation table */

struct kbsentry {
    char kb_func;
    char[512] kb_string;
}
enum KDGKBSENT = 0x4B48; /* gets one function key string entry */
enum KDSKBSENT = 0x4B49; /* sets one function key string entry */

struct kbdiacr {
    char diacr, base, result;
}

struct kbdiacrs {
    uint kb_cnt; /* number of entries in following array */
    kbdiacr[256] kbdiacr_; /* MAX_DIACR from keyboard.h */
}

enum KDGKBDIACR = 0x4B4A; /* read kernel accent table */
enum KDSKBDIACR = 0x4B4B; /* write kernel accent table */

struct kbdiacruc {
    uint diacr, base, result;
}

struct kbdiacrsuc {
    uint kb_cnt; /* number of entries in following array */
    kbdiacruc[256] kbdiacruc_; /* MAX_DIACR from keyboard.h */
}

enum KDGKBDIACRUC = 0x4BFA; /* read kernel accent table - UCS */
enum KDSKBDIACRUC = 0x4BFB; /* write kernel accent table - UCS */

struct kbkeycode {
    uint scancode, keycode;
}

enum KDGETKEYCODE = 0x4B4C; /* read kernel keycode table entry */
enum KDSETKEYCODE = 0x4B4D; /* write kernel keycode table entry */

enum KDSIGACCEPT = 0x4B4E; /* accept kbd generated signals */

struct kbd_repeat {
    int delay; /* in msec; <= 0: don't change */
    int period; /* in msec; <= 0: don't change */
    /* earlier this field was misnamed "rate" */
}

enum KDKBDREP = 0x4B52; /* set keyboard delay/repeat rate;
     * actually used values are returned */

enum KDFONTOP = 0x4B72; /* font operations */

struct console_font_op {
    uint op; /* operation code KD_FONT_OP_* */
    uint flags; /* KD_FONT_FLAG_* */
    uint width, height; /* font size */
    uint charcount;
    char* data; /* font data with height fixed to 32 */
}

struct console_font {
    uint width, height; /* font size */
    uint charcount;
    char* data; /* font data with height fixed to 32 */
}

enum KD_FONT_OP_SET = 0; /* Set font */
enum KD_FONT_OP_GET = 1; /* Get font */
enum KD_FONT_OP_SET_DEFAULT = 2; /* Set font to default, data points to name / NULL */
enum KD_FONT_OP_COPY = 3; /* Obsolete, do not use */

enum KD_FONT_FLAG_DONT_RECALC = 1; /* Don't recalculate hw charcell size [compat] */

/* note: 0x4B00-0x4B4E all have had a value at some time;
   don't reuse for the time being */
/* note: 0x4B60-0x4B6D, 0x4B70-0x4B72 used above */
