from django.shortcuts import render
from django.http import HttpResponse

import pandas as pd
import altair as alt

# Create your views here.
# request handler
# request -> response

def index(request):
    htotal_df = pd.read_csv('playground/htotal_df.csv')
    htotal_df['count'] = round(htotal_df['count_x'] + htotal_df['count_y'], 2)
    htotal_df['perc'] = round(htotal_df['count']*100/htotal_df.loc[htotal_df['timeStamp']==1, 'count'].sum(), 2)
    tud = htotal_df

    if request.method == "POST":
        if request.POST['bu']=="50% UP":
            tud = pd.read_csv('playground/htotal_df.csv')
            tud['count'] = round(tud['count_x']*0.5 + tud['count_y']*0.5, 2)
            tud['perc'] = round(tud['perc_x']*0.5 + tud['perc_y']*0.5, 2)
        elif request.POST['bu']=="80% UP":
            tud = pd.read_csv('playground/htotal_df.csv')
            tud['count'] = round(tud['count_x']*0.2 + tud['count_y']*0.8, 2)
            tud['perc'] = round(tud['perc_x']*0.2 + tud['perc_y']*0.8, 2)

    chart = two_main_charts(tud)

    chart1 = one_area(tud, "Adult Care", "red")
    chart2 = one_area(tud, "Work and Education", "red")
    chart3 = one_area(tud, "Child Care", "red")


    chart5 = one_area(htotal_df, "Adult Care", "#4c78a8")
    chart6 = one_area(htotal_df, "Work and Education", "#eeca3b")
    chart7 = one_area(htotal_df, "Child Care", "#f58518")

    dater = dict(calculate_total_time(htotal_df) - calculate_total_time(tud))

    if request.method == "POST" and request.POST['bu']!="Original":
        chart4 = chart & (chart6 + chart2 | chart1 + chart5 | chart7 + chart3)

        W = {'percent': round(abs(dater['Work and Education']*100), 2), 'total_time': round(abs(dater['Work and Education'])*434 * 24)}

        AC = {'percent': round(abs(dater['Adult Care']*100), 2), 'total_time': round(abs(dater['Adult Care'])*434 * 24)}

        CC = {'percent': round(abs(dater['Child Care']*100), 2), 'total_time': round(abs(dater['Child Care'])*434 * 24)}
    else: 
        chart4 = chart & (chart6 | chart5 | chart7)
        AC, W, CC = None, None, None

    
    return render(request, 'index.html', {'AC': AC, 'W': W, 'CC': CC, 'chart1': chart4.to_json()})


def say_hello(request):
    htotal_df = pd.read_csv('playground/htotal_df.csv')
    htotal_df['count'] = round(htotal_df['count_x'] + htotal_df['count_y'], 2)
    htotal_df['perc'] = round(htotal_df['count']*100/htotal_df.loc[htotal_df['timeStamp']==1, 'count'].sum(), 2)
    tud = htotal_df

    if request.method == "POST":
        if request.POST['bu']=="50% UP":
            tud = pd.read_csv('playground/htotal_df.csv')
            tud['count'] = round(tud['count_x']*0.5 + tud['count_y']*0.5, 2)
            tud['perc'] = round(tud['perc_x']*0.5 + tud['perc_y']*0.5, 2)
        elif request.POST['bu']=="80% UP":
            tud = pd.read_csv('playground/htotal_df.csv')
            tud['count'] = round(tud['count_x']*0.2 + tud['count_y']*0.8, 2)
            tud['perc'] = round(tud['perc_x']*0.2 + tud['perc_y']*0.8, 2)

    chart = two_main_charts(tud)

    chart1 = one_area(tud, "Adult Care", "red")
    chart2 = one_area(tud, "Work and Education", "red")
    chart3 = one_area(tud, "Child Care", "red")


    chart5 = one_area(htotal_df, "Adult Care", "#4c78a8")
    chart6 = one_area(htotal_df, "Work and Education", "#eeca3b")
    chart7 = one_area(htotal_df, "Child Care", "#f58518")

    dater = dict(calculate_total_time(htotal_df) - calculate_total_time(tud))

    if request.method == "POST" and request.POST['bu']!="Original":
        chart4 = chart & (chart6 + chart2 | chart1 + chart5 | chart7 + chart3)

        W = {'percent': round(abs(dater['Work and Education']*100), 2), 'total_time': round(abs(dater['Work and Education'])*434_000_000 * 24)}

        AC = {'percent': round(abs(dater['Adult Care']*100), 2), 'total_time': round(abs(dater['Adult Care'])*434_000_000 * 24)}

        CC = {'percent': round(abs(dater['Child Care']*100), 2), 'total_time': round(abs(dater['Child Care'])*434_000_000 * 24)}
    else: 
        chart4 = chart & (chart6 | chart5 | chart7)
        AC, W, CC = None, None, None

    
    return render(request, 'hello.html', {'AC': AC, 'W': W, 'CC': CC, 'chart1': chart4.to_json()})


def two_main_charts(tud):
    alt.data_transformers.disable_max_rows()

    areaP = alt.Chart(tud).mark_area().encode(
        x = alt.X("time:T", axis=alt.Axis(format='%H:%M %p')),
        y=alt.Y('perc:Q', stack="normalize", axis=alt.Axis(format='%'), title = "Percent of Observations"),
        color="activity:N"
    )

    nearest = alt.selection(type='single', nearest=True, on='mouseover',
                            fields=['time'], empty='none')

    # Transparent selectors across the chart. This is what tells us
    # the x-value of the cursor
    selectors = alt.Chart(tud).mark_point().encode(
            x='time:T',
            opacity=alt.value(0), 
        ).add_selection(
            nearest
    )

    # Draw points on the line, and highlight based on selection
    points = areaP.mark_point().encode(
        opacity=alt.condition(nearest, alt.value(1), alt.value(0))
    )

    # Draw text labels near the points, and highlight based on selection
    text = areaP.mark_text(align='left', dx=5, dy=-5).encode(
        text=alt.condition(nearest, "perc:Q", alt.value(' '))
    )

    # Draw a rule at the location of the selection
    rules = alt.Chart(tud).mark_rule(color='gray').encode(
            x='time:T',
        ).transform_filter(
            nearest
    )

    # Put the five layers into a chart and bind the data
    chart = alt.layer(
            areaP, selectors, points, rules, text
        ).properties(
            width=600, height=300
    ).properties(
        title = "Activities Throughout the Day"
    )

    chart2 = alt.Chart(tud).transform_joinaggregate(
            TotalTime='sum(count)',
        ).transform_joinaggregate(
            TotalTimeByAct='sum(count)',
            groupby=['activity']
        ).transform_calculate(
            PercentOfTotal="datum.TotalTimeByAct / datum.TotalTime"
        ).mark_bar().encode(
            alt.X('PercentOfTotal:Q', axis=alt.Axis(format='%'), title="Percent of Total"),
            y=alt.Y('activity:N', sort='x', title="Activity"),
            color='activity:N',
            tooltip=alt.Tooltip('PercentOfTotal:Q', title="Percentage", format='.0%')
        ).properties(
            width=600, height=100
        ).properties(
            title = "Percentage of Total Activities"
        )
    
    chart1 = chart & chart2

    return chart1

def one_area(data, act, colo, opac=0.8):
    alt.data_transformers.disable_max_rows()

    chart = alt.Chart(data[data['activity']==act]).mark_area(color = colo, opacity=opac).encode(
        x = alt.X("time:T", axis=alt.Axis(format='%H:%M %p')),
        y=alt.Y('perc:Q', title = "Percent")
        #y=alt.Y('perc:Q', title = "Percent", scale=alt.Scale(domain=[0, 40]))
    ).properties(
        title = act,
        width = 160,
        height = 100
    )

    return chart

def calculate_total_time(df):    
    return df.groupby('activity').sum()['perc']/df['perc'].sum()