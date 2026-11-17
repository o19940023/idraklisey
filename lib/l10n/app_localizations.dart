import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In az, this message translates to:
  /// **'İdrak Liseyi'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In az, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In az, this message translates to:
  /// **'Ləğv et'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In az, this message translates to:
  /// **'Yadda saxla'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In az, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In az, this message translates to:
  /// **'Redaktə et'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In az, this message translates to:
  /// **'Əlavə et'**
  String get add;

  /// No description provided for @search.
  ///
  /// In az, this message translates to:
  /// **'Axtar'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In az, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @back.
  ///
  /// In az, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @next.
  ///
  /// In az, this message translates to:
  /// **'Növbəti'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In az, this message translates to:
  /// **'Əvvəlki'**
  String get previous;

  /// No description provided for @close.
  ///
  /// In az, this message translates to:
  /// **'Bağla'**
  String get close;

  /// No description provided for @done.
  ///
  /// In az, this message translates to:
  /// **'Hazır'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In az, this message translates to:
  /// **'Təsdiq et'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In az, this message translates to:
  /// **'Yüklənir...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In az, this message translates to:
  /// **'Xəta'**
  String get error;

  /// No description provided for @success.
  ///
  /// In az, this message translates to:
  /// **'Uğurlu'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In az, this message translates to:
  /// **'Xəbərdarlıq'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In az, this message translates to:
  /// **'Məlumat'**
  String get info;

  /// No description provided for @yes.
  ///
  /// In az, this message translates to:
  /// **'Bəli'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In az, this message translates to:
  /// **'Xeyr'**
  String get no;

  /// No description provided for @login.
  ///
  /// In az, this message translates to:
  /// **'Daxil ol'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In az, this message translates to:
  /// **'Çıxış'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In az, this message translates to:
  /// **'Hesabdan çıxmaq istədiyinizdən əminsiniz?'**
  String get logoutConfirm;

  /// No description provided for @email.
  ///
  /// In az, this message translates to:
  /// **'E-poçt'**
  String get email;

  /// No description provided for @password.
  ///
  /// In az, this message translates to:
  /// **'Şifrə'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni unutmusunuz?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In az, this message translates to:
  /// **'Məni xatırla'**
  String get rememberMe;

  /// No description provided for @dashboard.
  ///
  /// In az, this message translates to:
  /// **'Panel'**
  String get dashboard;

  /// No description provided for @welcomeBack.
  ///
  /// In az, this message translates to:
  /// **'Xoş gəlmisiniz'**
  String get welcomeBack;

  /// No description provided for @goodMorning.
  ///
  /// In az, this message translates to:
  /// **'Sabahınız xeyir'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In az, this message translates to:
  /// **'Gününüz xeyir'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In az, this message translates to:
  /// **'Axşamınız xeyir'**
  String get goodEvening;

  /// No description provided for @student.
  ///
  /// In az, this message translates to:
  /// **'Şagird'**
  String get student;

  /// No description provided for @students.
  ///
  /// In az, this message translates to:
  /// **'Şagirdlər'**
  String get students;

  /// No description provided for @studentDashboard.
  ///
  /// In az, this message translates to:
  /// **'Şagird Paneli'**
  String get studentDashboard;

  /// No description provided for @studentProfile.
  ///
  /// In az, this message translates to:
  /// **'Şagird Profili'**
  String get studentProfile;

  /// No description provided for @studentManagement.
  ///
  /// In az, this message translates to:
  /// **'Şagird İdarəsi'**
  String get studentManagement;

  /// No description provided for @studentPortal.
  ///
  /// In az, this message translates to:
  /// **'ŞAGİRD PORTALI'**
  String get studentPortal;

  /// No description provided for @myGrades.
  ///
  /// In az, this message translates to:
  /// **'Qiymətlərim'**
  String get myGrades;

  /// No description provided for @myAssignments.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıqlarım'**
  String get myAssignments;

  /// No description provided for @myTimetable.
  ///
  /// In az, this message translates to:
  /// **'Dərs Cədvəlim'**
  String get myTimetable;

  /// No description provided for @digitalId.
  ///
  /// In az, this message translates to:
  /// **'Rəqəmsal Vəsiqə'**
  String get digitalId;

  /// No description provided for @digitalIdCard.
  ///
  /// In az, this message translates to:
  /// **'Digital ID Kartı'**
  String get digitalIdCard;

  /// No description provided for @digitalIdDesc.
  ///
  /// In az, this message translates to:
  /// **'Turniket & Kimlik Passı'**
  String get digitalIdDesc;

  /// No description provided for @teacher.
  ///
  /// In az, this message translates to:
  /// **'Müəllim'**
  String get teacher;

  /// No description provided for @teachers.
  ///
  /// In az, this message translates to:
  /// **'Müəllimlər'**
  String get teachers;

  /// No description provided for @teacherDashboard.
  ///
  /// In az, this message translates to:
  /// **'Müəllim Paneli'**
  String get teacherDashboard;

  /// No description provided for @teacherProfile.
  ///
  /// In az, this message translates to:
  /// **'Müəllim Profili'**
  String get teacherProfile;

  /// No description provided for @teacherHub.
  ///
  /// In az, this message translates to:
  /// **'MÜƏLLİM HUB'**
  String get teacherHub;

  /// No description provided for @myClasses.
  ///
  /// In az, this message translates to:
  /// **'Siniflərim'**
  String get myClasses;

  /// No description provided for @gradeStudents.
  ///
  /// In az, this message translates to:
  /// **'Şagirdləri Qiymətləndir'**
  String get gradeStudents;

  /// No description provided for @quickGrading.
  ///
  /// In az, this message translates to:
  /// **'Sürətli Qiymətləndirmə'**
  String get quickGrading;

  /// No description provided for @voiceToTextReview.
  ///
  /// In az, this message translates to:
  /// **'Voice-to-Text rəy'**
  String get voiceToTextReview;

  /// No description provided for @teacherIdCard.
  ///
  /// In az, this message translates to:
  /// **'Müəllim Vəsiqəsi'**
  String get teacherIdCard;

  /// No description provided for @teacherIdCardDesc.
  ///
  /// In az, this message translates to:
  /// **'NFC Turniket, otaq açarı və 3D səlahiyyət kartı'**
  String get teacherIdCardDesc;

  /// No description provided for @pedagogicalStaff.
  ///
  /// In az, this message translates to:
  /// **'PEDAQOJİ HEYƏT'**
  String get pedagogicalStaff;

  /// No description provided for @parent.
  ///
  /// In az, this message translates to:
  /// **'Valideyn'**
  String get parent;

  /// No description provided for @parents.
  ///
  /// In az, this message translates to:
  /// **'Valideynlər'**
  String get parents;

  /// No description provided for @parentDashboard.
  ///
  /// In az, this message translates to:
  /// **'Valideyn Paneli'**
  String get parentDashboard;

  /// No description provided for @parentCabinet.
  ///
  /// In az, this message translates to:
  /// **'VALİDEYN KABİNETİ'**
  String get parentCabinet;

  /// No description provided for @myChildren.
  ///
  /// In az, this message translates to:
  /// **'Övladlarım'**
  String get myChildren;

  /// No description provided for @yourChildren.
  ///
  /// In az, this message translates to:
  /// **'Övladlarınız'**
  String get yourChildren;

  /// No description provided for @childPerformance.
  ///
  /// In az, this message translates to:
  /// **'Övladımın göstəriciləri'**
  String get childPerformance;

  /// No description provided for @admin.
  ///
  /// In az, this message translates to:
  /// **'İnzibatçı'**
  String get admin;

  /// No description provided for @adminDashboard.
  ///
  /// In az, this message translates to:
  /// **'İnzibatçı Paneli'**
  String get adminDashboard;

  /// No description provided for @administration.
  ///
  /// In az, this message translates to:
  /// **'İnzibatçılıq'**
  String get administration;

  /// No description provided for @schoolAdmin.
  ///
  /// In az, this message translates to:
  /// **'MƏKTƏB İDARƏETMƏSİ'**
  String get schoolAdmin;

  /// No description provided for @userManagement.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi İdarəsi'**
  String get userManagement;

  /// No description provided for @roleManagement.
  ///
  /// In az, this message translates to:
  /// **'Rol İdarəetməsi'**
  String get roleManagement;

  /// No description provided for @systemSettings.
  ///
  /// In az, this message translates to:
  /// **'Sistem Ayarları'**
  String get systemSettings;

  /// No description provided for @timetable.
  ///
  /// In az, this message translates to:
  /// **'Dərs Cədvəli'**
  String get timetable;

  /// No description provided for @timetableDesc.
  ///
  /// In az, this message translates to:
  /// **'Həftəlik dərslər'**
  String get timetableDesc;

  /// No description provided for @assignments.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıqlar'**
  String get assignments;

  /// No description provided for @assignmentsDesc.
  ///
  /// In az, this message translates to:
  /// **'Ev tapşırıqları'**
  String get assignmentsDesc;

  /// No description provided for @library.
  ///
  /// In az, this message translates to:
  /// **'E-Kitabxana'**
  String get library;

  /// No description provided for @libraryDesc.
  ///
  /// In az, this message translates to:
  /// **'Dərslik və ədəbiyyat'**
  String get libraryDesc;

  /// No description provided for @cafeteria.
  ///
  /// In az, this message translates to:
  /// **'Yeməkxana'**
  String get cafeteria;

  /// No description provided for @cafeteriaDesc.
  ///
  /// In az, this message translates to:
  /// **'Həftəlik menyu'**
  String get cafeteriaDesc;

  /// No description provided for @cafeteriaMenu.
  ///
  /// In az, this message translates to:
  /// **'Yeməkxana Menyusu'**
  String get cafeteriaMenu;

  /// No description provided for @grades.
  ///
  /// In az, this message translates to:
  /// **'Qiymətlər'**
  String get grades;

  /// No description provided for @gradesDesc.
  ///
  /// In az, this message translates to:
  /// **'Akademik dinamika'**
  String get gradesDesc;

  /// No description provided for @attendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət'**
  String get attendance;

  /// No description provided for @attendanceDesc.
  ///
  /// In az, this message translates to:
  /// **'Dərslərə davamiyyət'**
  String get attendanceDesc;

  /// No description provided for @meetIdrak.
  ///
  /// In az, this message translates to:
  /// **'Meet İdrak'**
  String get meetIdrak;

  /// No description provided for @meetIdrakDesc.
  ///
  /// In az, this message translates to:
  /// **'Səsli & Video otaqlar'**
  String get meetIdrakDesc;

  /// No description provided for @notifications.
  ///
  /// In az, this message translates to:
  /// **'Bildirişlər'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In az, this message translates to:
  /// **'Yeni xəbərlər'**
  String get notificationsDesc;

  /// No description provided for @helpdesk.
  ///
  /// In az, this message translates to:
  /// **'Helpdesk'**
  String get helpdesk;

  /// No description provided for @helpdeskDesc.
  ///
  /// In az, this message translates to:
  /// **'Müraciət sistemi'**
  String get helpdeskDesc;

  /// No description provided for @analytics.
  ///
  /// In az, this message translates to:
  /// **'Statistika'**
  String get analytics;

  /// No description provided for @analyticsDesc.
  ///
  /// In az, this message translates to:
  /// **'Analitik hesabatlar'**
  String get analyticsDesc;

  /// No description provided for @inventory.
  ///
  /// In az, this message translates to:
  /// **'İnventar'**
  String get inventory;

  /// No description provided for @inventoryDesc.
  ///
  /// In az, this message translates to:
  /// **'QR inventar sistemi'**
  String get inventoryDesc;

  /// No description provided for @settings.
  ///
  /// In az, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In az, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @appearance.
  ///
  /// In az, this message translates to:
  /// **'Görünüş'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In az, this message translates to:
  /// **'Tünd Rejim'**
  String get darkMode;

  /// No description provided for @darkModeActive.
  ///
  /// In az, this message translates to:
  /// **'Tünd tema aktivdir'**
  String get darkModeActive;

  /// No description provided for @lightModeActive.
  ///
  /// In az, this message translates to:
  /// **'İşıqlı tema aktivdir'**
  String get lightModeActive;

  /// No description provided for @language.
  ///
  /// In az, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @languageSettings.
  ///
  /// In az, this message translates to:
  /// **'Dil Ayarları'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In az, this message translates to:
  /// **'Dil seçin'**
  String get selectLanguage;

  /// No description provided for @customization.
  ///
  /// In az, this message translates to:
  /// **'Fərdiləşdirmə'**
  String get customization;

  /// No description provided for @customizeModules.
  ///
  /// In az, this message translates to:
  /// **'Alt Menyu Fərdiləşdir'**
  String get customizeModules;

  /// No description provided for @customizeModulesDesc.
  ///
  /// In az, this message translates to:
  /// **'Modulların sırasını və görünməsini dəyişdir'**
  String get customizeModulesDesc;

  /// No description provided for @pushNotifications.
  ///
  /// In az, this message translates to:
  /// **'Push Bildirişlər'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In az, this message translates to:
  /// **'Yeni bildirişlər üçün xəbərdarlıqlar'**
  String get pushNotificationsDesc;

  /// No description provided for @account.
  ///
  /// In az, this message translates to:
  /// **'Hesab'**
  String get account;

  /// No description provided for @accountSettings.
  ///
  /// In az, this message translates to:
  /// **'Hesab Ayarları'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni dəyişdir'**
  String get changePassword;

  /// No description provided for @privacy.
  ///
  /// In az, this message translates to:
  /// **'Məxfilik'**
  String get privacy;

  /// No description provided for @privacyPolicy.
  ///
  /// In az, this message translates to:
  /// **'Məxfilik Siyasəti'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In az, this message translates to:
  /// **'İstifadə Şərtləri'**
  String get termsOfService;

  /// No description provided for @help.
  ///
  /// In az, this message translates to:
  /// **'Kömək'**
  String get help;

  /// No description provided for @helpCenter.
  ///
  /// In az, this message translates to:
  /// **'Kömək Mərkəzi'**
  String get helpCenter;

  /// No description provided for @about.
  ///
  /// In az, this message translates to:
  /// **'Haqqında'**
  String get about;

  /// No description provided for @version.
  ///
  /// In az, this message translates to:
  /// **'Versiya'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In az, this message translates to:
  /// **'Build nömrəsi'**
  String get buildNumber;

  /// No description provided for @appInfo.
  ///
  /// In az, this message translates to:
  /// **'Tətbiq məlumatı'**
  String get appInfo;

  /// No description provided for @digitalEducationPlatform.
  ///
  /// In az, this message translates to:
  /// **'Rəqəmsal Təhsil Platforması'**
  String get digitalEducationPlatform;

  /// No description provided for @create.
  ///
  /// In az, this message translates to:
  /// **'Yarat'**
  String get create;

  /// No description provided for @createNew.
  ///
  /// In az, this message translates to:
  /// **'Yeni yarat'**
  String get createNew;

  /// No description provided for @update.
  ///
  /// In az, this message translates to:
  /// **'Yenilə'**
  String get update;

  /// No description provided for @view.
  ///
  /// In az, this message translates to:
  /// **'Bax'**
  String get view;

  /// No description provided for @viewAll.
  ///
  /// In az, this message translates to:
  /// **'Hamısına bax'**
  String get viewAll;

  /// No description provided for @download.
  ///
  /// In az, this message translates to:
  /// **'Yüklə'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In az, this message translates to:
  /// **'Yüklə'**
  String get upload;

  /// No description provided for @share.
  ///
  /// In az, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @print.
  ///
  /// In az, this message translates to:
  /// **'Çap et'**
  String get print;

  /// No description provided for @export.
  ///
  /// In az, this message translates to:
  /// **'İxrac et'**
  String get export;

  /// No description provided for @import.
  ///
  /// In az, this message translates to:
  /// **'İdxal et'**
  String get import;

  /// No description provided for @today.
  ///
  /// In az, this message translates to:
  /// **'Bu gün'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In az, this message translates to:
  /// **'Dünən'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In az, this message translates to:
  /// **'Sabah'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In az, this message translates to:
  /// **'Bu həftə'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In az, this message translates to:
  /// **'Keçən həftə'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In az, this message translates to:
  /// **'Bu ay'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In az, this message translates to:
  /// **'Keçən ay'**
  String get lastMonth;

  /// No description provided for @date.
  ///
  /// In az, this message translates to:
  /// **'Tarix'**
  String get date;

  /// No description provided for @time.
  ///
  /// In az, this message translates to:
  /// **'Vaxt'**
  String get time;

  /// No description provided for @duration.
  ///
  /// In az, this message translates to:
  /// **'Müddət'**
  String get duration;

  /// No description provided for @classLabel.
  ///
  /// In az, this message translates to:
  /// **'Sinif'**
  String get classLabel;

  /// No description provided for @classes.
  ///
  /// In az, this message translates to:
  /// **'Siniflər'**
  String get classes;

  /// No description provided for @classManagement.
  ///
  /// In az, this message translates to:
  /// **'Sinif İdarəsi'**
  String get classManagement;

  /// No description provided for @subject.
  ///
  /// In az, this message translates to:
  /// **'Fənn'**
  String get subject;

  /// No description provided for @subjects.
  ///
  /// In az, this message translates to:
  /// **'Fənnlər'**
  String get subjects;

  /// No description provided for @lesson.
  ///
  /// In az, this message translates to:
  /// **'Dərs'**
  String get lesson;

  /// No description provided for @lessons.
  ///
  /// In az, this message translates to:
  /// **'Dərslər'**
  String get lessons;

  /// No description provided for @exam.
  ///
  /// In az, this message translates to:
  /// **'İmtahan'**
  String get exam;

  /// No description provided for @exams.
  ///
  /// In az, this message translates to:
  /// **'İmtahanlar'**
  String get exams;

  /// No description provided for @homework.
  ///
  /// In az, this message translates to:
  /// **'Ev tapşırığı'**
  String get homework;

  /// No description provided for @report.
  ///
  /// In az, this message translates to:
  /// **'Hesabat'**
  String get report;

  /// No description provided for @reports.
  ///
  /// In az, this message translates to:
  /// **'Hesabatlar'**
  String get reports;

  /// No description provided for @semester.
  ///
  /// In az, this message translates to:
  /// **'Semestr'**
  String get semester;

  /// No description provided for @studentsCount.
  ///
  /// In az, this message translates to:
  /// **'Şagirdlər'**
  String get studentsCount;

  /// No description provided for @assignmentsCount.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıqlar'**
  String get assignmentsCount;

  /// No description provided for @booksCount.
  ///
  /// In az, this message translates to:
  /// **'E-Kitablar'**
  String get booksCount;

  /// No description provided for @classesCount.
  ///
  /// In az, this message translates to:
  /// **'Siniflər'**
  String get classesCount;

  /// No description provided for @teachersCount.
  ///
  /// In az, this message translates to:
  /// **'Müəllimlər'**
  String get teachersCount;

  /// No description provided for @ticketsCount.
  ///
  /// In az, this message translates to:
  /// **'Müraciətlər'**
  String get ticketsCount;

  /// No description provided for @active.
  ///
  /// In az, this message translates to:
  /// **'Aktiv'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In az, this message translates to:
  /// **'Qeyri-aktiv'**
  String get inactive;

  /// No description provided for @pending.
  ///
  /// In az, this message translates to:
  /// **'Gözləyir'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In az, this message translates to:
  /// **'Tamamlandı'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In az, this message translates to:
  /// **'Davam edir'**
  String get inProgress;

  /// No description provided for @cancelled.
  ///
  /// In az, this message translates to:
  /// **'Ləğv edilib'**
  String get cancelled;

  /// No description provided for @approved.
  ///
  /// In az, this message translates to:
  /// **'Təsdiqlənib'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In az, this message translates to:
  /// **'Rədd edilib'**
  String get rejected;

  /// No description provided for @noDataAvailable.
  ///
  /// In az, this message translates to:
  /// **'Məlumat yoxdur'**
  String get noDataAvailable;

  /// No description provided for @noResultsFound.
  ///
  /// In az, this message translates to:
  /// **'Nəticə tapılmadı'**
  String get noResultsFound;

  /// No description provided for @comingSoon.
  ///
  /// In az, this message translates to:
  /// **'Tezliklə'**
  String get comingSoon;

  /// No description provided for @underDevelopment.
  ///
  /// In az, this message translates to:
  /// **'Hazırlanır'**
  String get underDevelopment;

  /// No description provided for @featureNotAvailable.
  ///
  /// In az, this message translates to:
  /// **'Bu funksiya hələ əlçatan deyil'**
  String get featureNotAvailable;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In az, this message translates to:
  /// **'Zəhmət olmasa yenidən cəhd edin'**
  String get pleaseTryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In az, this message translates to:
  /// **'Nəsə səhv getdi'**
  String get somethingWentWrong;

  /// No description provided for @successfullySaved.
  ///
  /// In az, this message translates to:
  /// **'Uğurla yadda saxlanıldı'**
  String get successfullySaved;

  /// No description provided for @successfullyDeleted.
  ///
  /// In az, this message translates to:
  /// **'Uğurla silindi'**
  String get successfullyDeleted;

  /// No description provided for @successfullyUpdated.
  ///
  /// In az, this message translates to:
  /// **'Uğurla yeniləndi'**
  String get successfullyUpdated;

  /// No description provided for @areYouSure.
  ///
  /// In az, this message translates to:
  /// **'Əminsiniz?'**
  String get areYouSure;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In az, this message translates to:
  /// **'Bu əməliyyat geri alına bilməz'**
  String get thisActionCannotBeUndone;

  /// No description provided for @azerbaijani.
  ///
  /// In az, this message translates to:
  /// **'Azərbaycan dili'**
  String get azerbaijani;

  /// No description provided for @english.
  ///
  /// In az, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In az, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @logoutDevice.
  ///
  /// In az, this message translates to:
  /// **'Bu cihazdan çıxış et'**
  String get logoutDevice;

  /// No description provided for @changePasswordDesc.
  ///
  /// In az, this message translates to:
  /// **'Hesab təhlükəsizliyi'**
  String get changePasswordDesc;

  /// No description provided for @faqDesc.
  ///
  /// In az, this message translates to:
  /// **'Tez-tez verilən suallar'**
  String get faqDesc;

  /// No description provided for @privacyDesc.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi məlumatları və gizlilik'**
  String get privacyDesc;

  /// No description provided for @termsDesc.
  ///
  /// In az, this message translates to:
  /// **'Xidmət şərtləri və qaydalar'**
  String get termsDesc;

  /// No description provided for @packageName.
  ///
  /// In az, this message translates to:
  /// **'Paket Adı'**
  String get packageName;

  /// No description provided for @build.
  ///
  /// In az, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @copyright.
  ///
  /// In az, this message translates to:
  /// **'© 2024-2026 İdrak Liseyi. Bütün hüquqlar qorunur.'**
  String get copyright;

  /// No description provided for @user.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi'**
  String get user;

  /// No description provided for @systemDefault.
  ///
  /// In az, this message translates to:
  /// **'Sistem dili (Avtomatik)'**
  String get systemDefault;

  /// No description provided for @languageChanged.
  ///
  /// In az, this message translates to:
  /// **'Dil dəyişdirildi'**
  String get languageChanged;

  /// No description provided for @usernameOrEmail.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı və ya e-poçt'**
  String get usernameOrEmail;

  /// No description provided for @enterUsername.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı daxil edin'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In az, this message translates to:
  /// **'Şifrə daxil edin'**
  String get enterPassword;

  /// No description provided for @loginButton.
  ///
  /// In az, this message translates to:
  /// **'Daxil ol'**
  String get loginButton;

  /// No description provided for @loggingIn.
  ///
  /// In az, this message translates to:
  /// **'Daxil olunur...'**
  String get loggingIn;

  /// No description provided for @loginError.
  ///
  /// In az, this message translates to:
  /// **'Zəhmət olmasa istifadəçi adı və şifrəni daxil edin'**
  String get loginError;

  /// No description provided for @biometricLogin.
  ///
  /// In az, this message translates to:
  /// **'Biometrik Giriş'**
  String get biometricLogin;

  /// No description provided for @biometricSetupMessage.
  ///
  /// In az, this message translates to:
  /// **'Növbəti dəfə daha sürətli giriş üçün {biometricName} istifadə etmək istəyirsiniz?'**
  String biometricSetupMessage(String biometricName);

  /// No description provided for @enableBiometric.
  ///
  /// In az, this message translates to:
  /// **'Aktivləşdir'**
  String get enableBiometric;

  /// No description provided for @notNow.
  ///
  /// In az, this message translates to:
  /// **'İndi yox'**
  String get notNow;

  /// No description provided for @welcomeToIdrak.
  ///
  /// In az, this message translates to:
  /// **'İdrak Liseyinə Xoş Gəlmisiniz'**
  String get welcomeToIdrak;

  /// No description provided for @digitalEducation.
  ///
  /// In az, this message translates to:
  /// **'Rəqəmsal Təhsil Platforması'**
  String get digitalEducation;

  /// No description provided for @switchAccountAndRole.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi Hesabı və Paneli'**
  String get switchAccountAndRole;

  /// No description provided for @switchRoleDesc.
  ///
  /// In az, this message translates to:
  /// **'Tətbiqdəki 4 rol arasında sürətli keçid edin:'**
  String get switchRoleDesc;

  /// No description provided for @adminRoleTitle.
  ///
  /// In az, this message translates to:
  /// **'Məktəb İnzibatçısı (Admin Paneli)'**
  String get adminRoleTitle;

  /// No description provided for @adminRoleDesc.
  ///
  /// In az, this message translates to:
  /// **'Hesab yaratma, şifrə təyini, müəllim yetkiləri və ümumi idarəetmə'**
  String get adminRoleDesc;

  /// No description provided for @teacherRoleTitle.
  ///
  /// In az, this message translates to:
  /// **'Müəllim Paneli (Teacher Hub)'**
  String get teacherRoleTitle;

  /// No description provided for @teacherRoleDesc.
  ///
  /// In az, this message translates to:
  /// **'Smart Davamiyyət, Səsli Rəy Qiymətləndirmə, QR İnventar Ticket'**
  String get teacherRoleDesc;

  /// No description provided for @studentRoleTitle.
  ///
  /// In az, this message translates to:
  /// **'Şagird Paneli (Student App)'**
  String get studentRoleTitle;

  /// No description provided for @studentRoleDesc.
  ///
  /// In az, this message translates to:
  /// **'Digital ID Kimlik, Tapşırıq Təhvili, Meet İdrak, E-Kitabxana, Yeməkxana Menyu'**
  String get studentRoleDesc;

  /// No description provided for @parentRoleTitle.
  ///
  /// In az, this message translates to:
  /// **'Valideyn Paneli (Parent Dashboard)'**
  String get parentRoleTitle;

  /// No description provided for @parentRoleDesc.
  ///
  /// In az, this message translates to:
  /// **'Həftəlik Matris Gündəlik, İnteraktiv Qrafiklər, Davamiyyət Təqvimi, Tibbi Kart'**
  String get parentRoleDesc;

  /// No description provided for @bottomNavCustomizeTitle.
  ///
  /// In az, this message translates to:
  /// **'Alt Menyu və Sürətli Tablar'**
  String get bottomNavCustomizeTitle;

  /// No description provided for @bottomNavCustomizeSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Aşağıda görünəcək düymələri seçin və sıralayın'**
  String get bottomNavCustomizeSubtitle;

  /// No description provided for @reset.
  ///
  /// In az, this message translates to:
  /// **'Sıfırla'**
  String get reset;

  /// No description provided for @activeTabs.
  ///
  /// In az, this message translates to:
  /// **'Aktiv tablar'**
  String get activeTabs;

  /// No description provided for @allAvailableModules.
  ///
  /// In az, this message translates to:
  /// **'Mövcud Bütün Modullar'**
  String get allAvailableModules;

  /// No description provided for @pinnedToBottomNav.
  ///
  /// In az, this message translates to:
  /// **'alt menyuya bərkidildi!'**
  String get pinnedToBottomNav;

  /// No description provided for @maxNavLimitReached.
  ///
  /// In az, this message translates to:
  /// **'Maksimum 5 alt menyu tabı seçilə bilər.'**
  String get maxNavLimitReached;

  /// No description provided for @gpaScore.
  ///
  /// In az, this message translates to:
  /// **'GPA Balı'**
  String get gpaScore;

  /// No description provided for @bloodGroup.
  ///
  /// In az, this message translates to:
  /// **'Qan Qrupu'**
  String get bloodGroup;

  /// No description provided for @studentNumber.
  ///
  /// In az, this message translates to:
  /// **'Şagird No'**
  String get studentNumber;

  /// No description provided for @todayLessons.
  ///
  /// In az, this message translates to:
  /// **'Bugünkü Dərslər'**
  String get todayLessons;

  /// No description provided for @noLessonsToday.
  ///
  /// In az, this message translates to:
  /// **'Bu gün üçün dərs yoxdur'**
  String get noLessonsToday;

  /// No description provided for @upcomingAssignments.
  ///
  /// In az, this message translates to:
  /// **'Yaxınlaşan Tapşırıqlar'**
  String get upcomingAssignments;

  /// No description provided for @noAssignments.
  ///
  /// In az, this message translates to:
  /// **'Aktiv tapşırıq yoxdur'**
  String get noAssignments;

  /// No description provided for @submitHomework.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığı Təhvil Ver'**
  String get submitHomework;

  /// No description provided for @submitted.
  ///
  /// In az, this message translates to:
  /// **'Təhvil Verilib'**
  String get submitted;

  /// No description provided for @notSubmitted.
  ///
  /// In az, this message translates to:
  /// **'Təhvil Verilməyib'**
  String get notSubmitted;

  /// No description provided for @deadline.
  ///
  /// In az, this message translates to:
  /// **'Son Tarix'**
  String get deadline;

  /// No description provided for @score.
  ///
  /// In az, this message translates to:
  /// **'Bal'**
  String get score;

  /// No description provided for @feedback.
  ///
  /// In az, this message translates to:
  /// **'Rəy'**
  String get feedback;

  /// No description provided for @scanQrCode.
  ///
  /// In az, this message translates to:
  /// **'QR Kodu Skan Edin'**
  String get scanQrCode;

  /// No description provided for @quickAttendance.
  ///
  /// In az, this message translates to:
  /// **'Sürətli Davamiyyət'**
  String get quickAttendance;

  /// No description provided for @present.
  ///
  /// In az, this message translates to:
  /// **'İştirak edir'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In az, this message translates to:
  /// **'Qayıb'**
  String get absent;

  /// No description provided for @late.
  ///
  /// In az, this message translates to:
  /// **'Gecikir'**
  String get late;

  /// No description provided for @excused.
  ///
  /// In az, this message translates to:
  /// **'İcazəli'**
  String get excused;

  /// No description provided for @saveAttendance.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyəti Yadda Saxla'**
  String get saveAttendance;

  /// No description provided for @voiceFeedback.
  ///
  /// In az, this message translates to:
  /// **'Səsli Rəy'**
  String get voiceFeedback;

  /// No description provided for @recordFeedback.
  ///
  /// In az, this message translates to:
  /// **'Səsi Yaz'**
  String get recordFeedback;

  /// No description provided for @recording.
  ///
  /// In az, this message translates to:
  /// **'Səs yazılır...'**
  String get recording;

  /// No description provided for @createAssignment.
  ///
  /// In az, this message translates to:
  /// **'Tapşırıq Yarat'**
  String get createAssignment;

  /// No description provided for @assignmentTitle.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığın Adı'**
  String get assignmentTitle;

  /// No description provided for @assignmentDescription.
  ///
  /// In az, this message translates to:
  /// **'Tapşırığın İzahı'**
  String get assignmentDescription;

  /// No description provided for @dueDate.
  ///
  /// In az, this message translates to:
  /// **'Təhvil Tarixi'**
  String get dueDate;

  /// No description provided for @selectClass.
  ///
  /// In az, this message translates to:
  /// **'Sinif Seçin'**
  String get selectClass;

  /// No description provided for @selectSubject.
  ///
  /// In az, this message translates to:
  /// **'Fənn Seçin'**
  String get selectSubject;

  /// No description provided for @createMeet.
  ///
  /// In az, this message translates to:
  /// **'Meet Yarat'**
  String get createMeet;

  /// No description provided for @roomName.
  ///
  /// In az, this message translates to:
  /// **'Otaq Adı'**
  String get roomName;

  /// No description provided for @joinMeet.
  ///
  /// In az, this message translates to:
  /// **'Meet-ə Qoşul'**
  String get joinMeet;

  /// No description provided for @activeRooms.
  ///
  /// In az, this message translates to:
  /// **'Aktiv Otaqlar'**
  String get activeRooms;

  /// No description provided for @noActiveRooms.
  ///
  /// In az, this message translates to:
  /// **'Aktiv otaq tapılmadı'**
  String get noActiveRooms;

  /// No description provided for @monitoringModules.
  ///
  /// In az, this message translates to:
  /// **'Nəzarət və İzləmə Modulları'**
  String get monitoringModules;

  /// No description provided for @monitoringModulesDesc.
  ///
  /// In az, this message translates to:
  /// **'Qiymətlər, davamiyyət, tibb və müəllim əlaqəsi'**
  String get monitoringModulesDesc;

  /// No description provided for @medicalCard.
  ///
  /// In az, this message translates to:
  /// **'Tibbi Kart'**
  String get medicalCard;

  /// No description provided for @allergies.
  ///
  /// In az, this message translates to:
  /// **'Allergiyalar'**
  String get allergies;

  /// No description provided for @chronicDiseases.
  ///
  /// In az, this message translates to:
  /// **'Xroniki Xəstəliklər'**
  String get chronicDiseases;

  /// No description provided for @vaccines.
  ///
  /// In az, this message translates to:
  /// **'Peyvəndlər'**
  String get vaccines;

  /// No description provided for @emergencyContact.
  ///
  /// In az, this message translates to:
  /// **'Təcili Əlaqə'**
  String get emergencyContact;

  /// No description provided for @attendanceCalendar.
  ///
  /// In az, this message translates to:
  /// **'Davamiyyət Təqvimi'**
  String get attendanceCalendar;

  /// No description provided for @monthlyAttendance.
  ///
  /// In az, this message translates to:
  /// **'Aylıq Davamiyyət Dinamikası'**
  String get monthlyAttendance;

  /// No description provided for @gradesAnalytics.
  ///
  /// In az, this message translates to:
  /// **'Qiymət Analitikası'**
  String get gradesAnalytics;

  /// No description provided for @parentTickets.
  ///
  /// In az, this message translates to:
  /// **'Valideyn Müraciətləri'**
  String get parentTickets;

  /// No description provided for @newTicket.
  ///
  /// In az, this message translates to:
  /// **'Yeni Müraciət'**
  String get newTicket;

  /// No description provided for @ticketSubject.
  ///
  /// In az, this message translates to:
  /// **'Müraciət Mövzusu'**
  String get ticketSubject;

  /// No description provided for @ticketMessage.
  ///
  /// In az, this message translates to:
  /// **'Müraciət Mətni'**
  String get ticketMessage;

  /// No description provided for @ticketDepartment.
  ///
  /// In az, this message translates to:
  /// **'Şöbə / Departament'**
  String get ticketDepartment;

  /// No description provided for @userList.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi Siyahısı'**
  String get userList;

  /// No description provided for @addUser.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi Əlavə Et'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçini Redaktə Et'**
  String get editUser;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In az, this message translates to:
  /// **'Bu istifadəçini silmək istədiyinizdən əminsiniz?'**
  String get deleteUserConfirm;

  /// No description provided for @studentRegistration.
  ///
  /// In az, this message translates to:
  /// **'Şagird Qeydiyyatı'**
  String get studentRegistration;

  /// No description provided for @createEmployee.
  ///
  /// In az, this message translates to:
  /// **'Əməkdaş Əlavə Et'**
  String get createEmployee;

  /// No description provided for @inventoryManagement.
  ///
  /// In az, this message translates to:
  /// **'İnventar İdarəsi'**
  String get inventoryManagement;

  /// No description provided for @itemBarcode.
  ///
  /// In az, this message translates to:
  /// **'İnventar / Barkod No'**
  String get itemBarcode;

  /// No description provided for @itemName.
  ///
  /// In az, this message translates to:
  /// **'Əşyanın Adı'**
  String get itemName;

  /// No description provided for @itemLocation.
  ///
  /// In az, this message translates to:
  /// **'Yerləşdiyi Otaq'**
  String get itemLocation;

  /// No description provided for @itemStatus.
  ///
  /// In az, this message translates to:
  /// **'Vəziyyəti'**
  String get itemStatus;

  /// No description provided for @timetableManagement.
  ///
  /// In az, this message translates to:
  /// **'Cədvəl İdarəsi'**
  String get timetableManagement;

  /// No description provided for @addClass.
  ///
  /// In az, this message translates to:
  /// **'Sinif Əlavə Et'**
  String get addClass;

  /// No description provided for @mergeClasses.
  ///
  /// In az, this message translates to:
  /// **'Sinifləri Birləşdir'**
  String get mergeClasses;

  /// No description provided for @totalStudents.
  ///
  /// In az, this message translates to:
  /// **'Ümumi Şagirdlər'**
  String get totalStudents;

  /// No description provided for @totalTeachers.
  ///
  /// In az, this message translates to:
  /// **'Ümumi Müəllimlər'**
  String get totalTeachers;

  /// No description provided for @totalParents.
  ///
  /// In az, this message translates to:
  /// **'Ümumi Valideynlər'**
  String get totalParents;

  /// No description provided for @activeTicketsCount.
  ///
  /// In az, this message translates to:
  /// **'Aktiv Müraciətlər'**
  String get activeTicketsCount;

  /// No description provided for @reorderModules.
  ///
  /// In az, this message translates to:
  /// **'Modul Sıralama'**
  String get reorderModules;

  /// No description provided for @finishReorder.
  ///
  /// In az, this message translates to:
  /// **'Sıralamanı Tamamla'**
  String get finishReorder;

  /// No description provided for @orderSaved.
  ///
  /// In az, this message translates to:
  /// **'Modulların yeni ardıcıllığı yadda saxlanıldı.'**
  String get orderSaved;

  /// No description provided for @dailyMenu.
  ///
  /// In az, this message translates to:
  /// **'Günün Nahar Menyusu'**
  String get dailyMenu;

  /// No description provided for @calories.
  ///
  /// In az, this message translates to:
  /// **'Kalori'**
  String get calories;

  /// No description provided for @allergens.
  ///
  /// In az, this message translates to:
  /// **'Allergenlər'**
  String get allergens;

  /// No description provided for @soup.
  ///
  /// In az, this message translates to:
  /// **'Şorba'**
  String get soup;

  /// No description provided for @mainDish.
  ///
  /// In az, this message translates to:
  /// **'Əsas Yemək'**
  String get mainDish;

  /// No description provided for @sideDish.
  ///
  /// In az, this message translates to:
  /// **'Qarnir'**
  String get sideDish;

  /// No description provided for @salad.
  ///
  /// In az, this message translates to:
  /// **'Salat'**
  String get salad;

  /// No description provided for @drink.
  ///
  /// In az, this message translates to:
  /// **'İçki'**
  String get drink;

  /// No description provided for @dessert.
  ///
  /// In az, this message translates to:
  /// **'Desert'**
  String get dessert;

  /// No description provided for @borrowBook.
  ///
  /// In az, this message translates to:
  /// **'Kitab Götür'**
  String get borrowBook;

  /// No description provided for @returnBook.
  ///
  /// In az, this message translates to:
  /// **'Kitabı Qaytar'**
  String get returnBook;

  /// No description provided for @bookAvailable.
  ///
  /// In az, this message translates to:
  /// **'Mövcuddur'**
  String get bookAvailable;

  /// No description provided for @bookBorrowed.
  ///
  /// In az, this message translates to:
  /// **'Götürülüb'**
  String get bookBorrowed;

  /// No description provided for @sendNotification.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş Göndər'**
  String get sendNotification;

  /// No description provided for @notificationTitle.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş Başlığı'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş Mətni'**
  String get notificationBody;

  /// No description provided for @selectRecipients.
  ///
  /// In az, this message translates to:
  /// **'Qəbul edənləri seçin'**
  String get selectRecipients;

  /// No description provided for @send.
  ///
  /// In az, this message translates to:
  /// **'Göndər'**
  String get send;

  /// No description provided for @sentSuccessfully.
  ///
  /// In az, this message translates to:
  /// **'Uğurla göndərildi'**
  String get sentSuccessfully;

  /// No description provided for @voiceRoom.
  ///
  /// In az, this message translates to:
  /// **'Səsli Otaq'**
  String get voiceRoom;

  /// No description provided for @mute.
  ///
  /// In az, this message translates to:
  /// **'Səsi Bağla'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In az, this message translates to:
  /// **'Səsi Aç'**
  String get unmute;

  /// No description provided for @leaveRoom.
  ///
  /// In az, this message translates to:
  /// **'Otaqdan Çıx'**
  String get leaveRoom;

  /// No description provided for @all.
  ///
  /// In az, this message translates to:
  /// **'Hamısı'**
  String get all;

  /// No description provided for @announcements.
  ///
  /// In az, this message translates to:
  /// **'Elanlar'**
  String get announcements;

  /// No description provided for @events.
  ///
  /// In az, this message translates to:
  /// **'Tədbirlər'**
  String get events;

  /// No description provided for @messages.
  ///
  /// In az, this message translates to:
  /// **'Mesajlar'**
  String get messages;

  /// No description provided for @markAllAsRead.
  ///
  /// In az, this message translates to:
  /// **'Hamısını oxunmuş et'**
  String get markAllAsRead;

  /// No description provided for @clearAll.
  ///
  /// In az, this message translates to:
  /// **'Hamısını təmizlə'**
  String get clearAll;

  /// No description provided for @noNotifications.
  ///
  /// In az, this message translates to:
  /// **'Bildiriş yoxdur'**
  String get noNotifications;

  /// No description provided for @fullName.
  ///
  /// In az, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In az, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In az, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @status.
  ///
  /// In az, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In az, this message translates to:
  /// **'Əməliyyatlar'**
  String get actions;

  /// No description provided for @details.
  ///
  /// In az, this message translates to:
  /// **'Ətraflı'**
  String get details;

  /// No description provided for @required.
  ///
  /// In az, this message translates to:
  /// **'Tələb olunur'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In az, this message translates to:
  /// **'İstəyə bağlı'**
  String get optional;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
