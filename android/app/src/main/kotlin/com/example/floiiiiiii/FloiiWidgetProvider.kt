package com.example.floiiiiiii

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget for Floii.
 *
 * The rich face (header, cycle stats and the month grid) is drawn in Flutter by
 * `HomeWidget.renderFlutterWidget` and stored as a PNG path under
 * `calendar_image`. This provider only binds that bitmap plus the two
 * deep-link buttons, so the widget matches the app's design without
 * duplicating the cycle logic here.
 */
class FloiiWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.floii_widget)

            // Tapping the widget face opens the app on the home screen.
            views.setOnClickPendingIntent(
                R.id.widget_image,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            // Restore the last rendered face. It is refreshed by the app on
            // launch, resume and every data change.
            val imagePath = widgetData.getString("calendar_image", null)
            val bitmap = imagePath?.let { BitmapFactory.decodeFile(it) }
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_image, bitmap)
            }

            val logPeriodLabel = widgetData.getString("log_period_label", null)
                ?: context.getString(R.string.floii_widget_log_period)
            views.setTextViewText(R.id.widget_log_period_label, logPeriodLabel)
            views.setOnClickPendingIntent(
                R.id.widget_log_period,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("floii://log-period"),
                ),
            )

            val logMoodLabel = widgetData.getString("log_mood_label", null)
                ?: context.getString(R.string.floii_widget_log_mood)
            views.setTextViewText(R.id.widget_log_mood_label, logMoodLabel)
            views.setOnClickPendingIntent(
                R.id.widget_log_mood,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("floii://log-mood"),
                ),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
