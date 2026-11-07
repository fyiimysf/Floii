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
 * Insights-overview home-screen widget for Floii.
 *
 * The hero overview card (phase, progress ring and next milestones) is drawn in
 * Flutter by `HomeWidget.renderFlutterWidget` and stored as a PNG path under
 * `insights_image`. This provider binds that bitmap and makes the whole face
 * open the app on the Insights tab.
 */
class FloiiInsightsWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.floii_insights_widget)

            views.setOnClickPendingIntent(
                R.id.widget_insights_image,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("floii://insights"),
                ),
            )

            val imagePath = widgetData.getString("insights_image", null)
            val bitmap = imagePath?.let { BitmapFactory.decodeFile(it) }
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_insights_image, bitmap)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
