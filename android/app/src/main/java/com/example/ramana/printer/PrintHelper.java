package com.example.ramana.printer;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.text.Layout;

import com.zcs.sdk.DriverManager;
import com.zcs.sdk.Printer;
import com.zcs.sdk.print.PrnStrFormat;

public class PrintHelper {

    public static String printBitmap(
            byte[] imageBytes,
            String cutMode
    ) {

        try {

            Printer printer =
                    DriverManager.getInstance().getPrinter();

            Bitmap bitmap =
                    BitmapFactory.decodeByteArray(
                            imageBytes,
                            0,
                            imageBytes.length
                    );

            printer.setPrintAppendBitmap(
                    bitmap,
                    Layout.Alignment.ALIGN_CENTER
            );

            PrnStrFormat format =
                    new PrnStrFormat();

            switch (cutMode) {

                case "NORMAL":

                    printer.setPrintStart();

                    printer.openPrnCutter((byte)1);

                    return "NORMAL_CUT_DONE";

                case "DELAY":

                    printer.setPrintStart();

                    Thread.sleep(2000);

                    printer.openPrnCutter((byte)1);

                    return "DELAY_CUT_DONE";

                case "FEED":

                    printer.setPrintAppendString(
                            "\n\n\n\n",
                            format
                    );

                    printer.setPrintStart();

                    Thread.sleep(1000);

                    printer.openPrnCutter((byte)1);

                    return "FEED_CUT_DONE";

                case "PARTIAL":

                    printer.setPrintStart();

                    Thread.sleep(1500);

                    printer.openPrnCutter((byte)0);

                    return "PARTIAL_CUT_DONE";

                case "LARGE_FEED":

                    printer.setPrintAppendString(
                            "\n\n\n\n\n\n\n\n\n\n",
                            format
                    );

                    printer.setPrintStart();

                    Thread.sleep(2500);

                    printer.openPrnCutter((byte)1);

                    return "LARGE_FEED_CUT_DONE";

                case "RAW":

                   // PrnStrFormat format = new PrnStrFormat();
                    format.setTextSize(25);
                   // format.setStyle(PrnTextStyle.NORMAL);
                    //format.setFont(PrnTextFont.MONOSPACE);

                    String textToPrint = "TEST STORE";
                    format.setAli(Layout.Alignment.ALIGN_CENTER);
                    printer.setPrintAppendString(textToPrint, format);

                    textToPrint = "test";
                    printer.setPrintAppendString(textToPrint, format);

                    textToPrint = "7778888857";
                    printer.setPrintAppendString(textToPrint, format);

                    format.setAli(Layout.Alignment.ALIGN_NORMAL);
                    textToPrint =
                            "-----------------------------------------\n" +  //monospace 25 text size, will be 41 characters
                                    "15/12/2023                       12:26 PM\n" +
                                    "Biller Name:Admin                        \n" +
                                    "-----------------------------------------\n" +
                                    "Item Name                   QTY   SP  Amt\n" +
                                    "-----------------------------------------\n" +
                                    "Food                          1 2.00 2.00\n" +
                                    "Home Care                     1 3.00 3.00\n" +
                                    "-----------------------------------------\n" +
                                    "Item/QTY:2/2\n" +
                                    "-----------------------------------------\n" +
                                    "Net Amount:                          5.00\n" +
                                    "-----------------------------------------\n" +
                                    "Cash Paid:                           5.00\n";
                    printer.setPrintAppendString(textToPrint, format);

                    format.setAli(Layout.Alignment.ALIGN_CENTER);
                    textToPrint = "Thank You. Come Again!";
                    printer.setPrintAppendString(textToPrint, format);
                    printer.setPrintAppendString("", format);

                    format.setAli(Layout.Alignment.ALIGN_NORMAL);
                    textToPrint = "E&0E                  Powered By SnapBizz";
                    printer.setPrintAppendString(textToPrint, format);
                    printer.setPrintAppendString("", format);
                    printer.setPrintAppendString("", format);
                    printer.setPrintStart();
                    printer.openPrnCutter((byte)1);

                    return "RAW_CUT_NOT_SUPPORTED_IN_THIS_SDK";
            }

            return "UNKNOWN_CUT_MODE";

        } catch (Exception e) {

            //e.printStackTrace();

            return "PRINT_FAILED : " + e.getMessage();
        }
    }
}