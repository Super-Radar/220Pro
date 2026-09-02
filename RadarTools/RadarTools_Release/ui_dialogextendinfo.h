/********************************************************************************
** Form generated from reading UI file 'dialogextendinfo.ui'
**
** Created by: Qt User Interface Compiler version 5.14.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_DIALOGEXTENDINFO_H
#define UI_DIALOGEXTENDINFO_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QDialog>
#include <QtWidgets/QGridLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QTextEdit>

QT_BEGIN_NAMESPACE

class Ui_DialogExtendInfo
{
public:
    QGridLayout *gridLayout_3;
    QGroupBox *groupBox;
    QGridLayout *gridLayout_2;
    QTextEdit *tEdit_Sort5;
    QLabel *label_3;
    QTextEdit *tEdit_Sort7;
    QLabel *label_2;
    QLabel *label;
    QTextEdit *tEdit_Sort2;
    QTextEdit *tEdit_Sort3;
    QTextEdit *tEdit_Sort6;
    QTextEdit *tEdit_Sort1;
    QTextEdit *tEdit_Sort8;
    QTextEdit *tEdit_Sort4;
    QLabel *label_9;
    QLabel *label_4;
    QTextEdit *tEdit_Sort9;
    QLabel *label_5;
    QLabel *label_11;
    QLabel *label_7;
    QLabel *label_10;
    QLabel *label_8;
    QTextEdit *tEdit_Sort10;
    QLineEdit *lEdit_selfStaus;
    QLabel *label_12;
    QLabel *label_22;
    QLineEdit *lEdit_selfBar;
    QLabel *label_23;
    QLineEdit *tEdit_selfCurAngle;
    QLabel *label_13;
    QLineEdit *tEdit_selfCurAccCnt;
    QLabel *label_14;
    QLineEdit *lineEditlog;
    QGroupBox *groupBox_3;
    QGridLayout *gridLayout;
    QHBoxLayout *horizontalLayout_2;
    QLabel *lb_tunnelFence;
    QHBoxLayout *horizontalLayout;
    QLabel *lb_ruralScene;
    QHBoxLayout *horizontalLayout_3;
    QLabel *lb_fenceScene;
    QHBoxLayout *horizontalLayout_4;
    QLabel *lb_barnScene;
    QGroupBox *groupBox_2;
    QGridLayout *gridLayout_4;
    QLabel *label_6;
    QLabel *label_24;
    QLineEdit *lEdit_loopTime;
    QLabel *label_20;
    QLineEdit *lEdit_VerticalAngle_Y;
    QLabel *label_29;
    QLineEdit *lEdit_AgcSW;
    QLabel *label_15;
    QLabel *label_18;
    QLabel *label_19;
    QLineEdit *lEdit_speedmode;
    QLineEdit *lEdit_installAngle;
    QLabel *label_26;
    QLineEdit *lEdit_horizontalOffset;
    QLabel *label_27;
    QLineEdit *lEdit_ProtocolVer;
    QLabel *label_21;
    QLineEdit *lEdit_EOLVAngleOffset;
    QLabel *label_30;
    QLabel *label_16;
    QLabel *label_25;
    QLabel *label_17;
    QLineEdit *lEdit_selfAngle;
    QLabel *label_28;
    QLineEdit *lEdit_AgcType;
    QLineEdit *lEdit_mcuTemperature;
    QLineEdit *lEdit_selfAnglePit;
    QLineEdit *lEdit_mmicTemperature;
    QLineEdit *lEdit_VerticalAngle_X;
    QLabel *label_31;
    QLineEdit *lEdit_servAnglePit;
    QLineEdit *lEdit_servAngleHrz;

    void setupUi(QDialog *DialogExtendInfo)
    {
        if (DialogExtendInfo->objectName().isEmpty())
            DialogExtendInfo->setObjectName(QString::fromUtf8("DialogExtendInfo"));
        DialogExtendInfo->resize(774, 448);
        DialogExtendInfo->setStyleSheet(QString::fromUtf8("background-color: rgb(39, 39, 39);\n"
"color: rgb(238, 238, 238);\n"
"\n"
"\n"
"\n"
""));
        gridLayout_3 = new QGridLayout(DialogExtendInfo);
        gridLayout_3->setObjectName(QString::fromUtf8("gridLayout_3"));
        groupBox = new QGroupBox(DialogExtendInfo);
        groupBox->setObjectName(QString::fromUtf8("groupBox"));
        groupBox->setStyleSheet(QString::fromUtf8("QGroupBox {\n"
"     border: 1.5px solid green;\n"
"     margin-top:2ex; \n"
"}\n"
"\n"
"QGroupBox::title {\n"
"     subcontrol-origin: margin;\n"
"     position: relative;\n"
"     left: 4px;\n"
"	 font: 16pt \"\351\273\221\344\275\223\";\n"
"}\n"
""));
        gridLayout_2 = new QGridLayout(groupBox);
        gridLayout_2->setObjectName(QString::fromUtf8("gridLayout_2"));
        tEdit_Sort5 = new QTextEdit(groupBox);
        tEdit_Sort5->setObjectName(QString::fromUtf8("tEdit_Sort5"));
        tEdit_Sort5->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort5, 1, 6, 1, 1);

        label_3 = new QLabel(groupBox);
        label_3->setObjectName(QString::fromUtf8("label_3"));

        gridLayout_2->addWidget(label_3, 0, 3, 1, 1);

        tEdit_Sort7 = new QTextEdit(groupBox);
        tEdit_Sort7->setObjectName(QString::fromUtf8("tEdit_Sort7"));
        tEdit_Sort7->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort7, 5, 2, 1, 1);

        label_2 = new QLabel(groupBox);
        label_2->setObjectName(QString::fromUtf8("label_2"));

        gridLayout_2->addWidget(label_2, 0, 2, 1, 1);

        label = new QLabel(groupBox);
        label->setObjectName(QString::fromUtf8("label"));

        gridLayout_2->addWidget(label, 0, 0, 1, 1);

        tEdit_Sort2 = new QTextEdit(groupBox);
        tEdit_Sort2->setObjectName(QString::fromUtf8("tEdit_Sort2"));
        tEdit_Sort2->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort2, 1, 2, 1, 1);

        tEdit_Sort3 = new QTextEdit(groupBox);
        tEdit_Sort3->setObjectName(QString::fromUtf8("tEdit_Sort3"));
        tEdit_Sort3->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort3, 1, 3, 1, 1);

        tEdit_Sort6 = new QTextEdit(groupBox);
        tEdit_Sort6->setObjectName(QString::fromUtf8("tEdit_Sort6"));
        tEdit_Sort6->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort6, 5, 0, 1, 1);

        tEdit_Sort1 = new QTextEdit(groupBox);
        tEdit_Sort1->setObjectName(QString::fromUtf8("tEdit_Sort1"));
        tEdit_Sort1->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort1, 1, 0, 1, 1);

        tEdit_Sort8 = new QTextEdit(groupBox);
        tEdit_Sort8->setObjectName(QString::fromUtf8("tEdit_Sort8"));
        tEdit_Sort8->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort8, 5, 3, 1, 1);

        tEdit_Sort4 = new QTextEdit(groupBox);
        tEdit_Sort4->setObjectName(QString::fromUtf8("tEdit_Sort4"));
        tEdit_Sort4->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort4, 1, 4, 1, 1);

        label_9 = new QLabel(groupBox);
        label_9->setObjectName(QString::fromUtf8("label_9"));

        gridLayout_2->addWidget(label_9, 0, 4, 1, 1);

        label_4 = new QLabel(groupBox);
        label_4->setObjectName(QString::fromUtf8("label_4"));

        gridLayout_2->addWidget(label_4, 2, 2, 1, 1);

        tEdit_Sort9 = new QTextEdit(groupBox);
        tEdit_Sort9->setObjectName(QString::fromUtf8("tEdit_Sort9"));
        tEdit_Sort9->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort9, 5, 4, 1, 1);

        label_5 = new QLabel(groupBox);
        label_5->setObjectName(QString::fromUtf8("label_5"));

        gridLayout_2->addWidget(label_5, 2, 4, 1, 1);

        label_11 = new QLabel(groupBox);
        label_11->setObjectName(QString::fromUtf8("label_11"));

        gridLayout_2->addWidget(label_11, 0, 6, 1, 1);

        label_7 = new QLabel(groupBox);
        label_7->setObjectName(QString::fromUtf8("label_7"));

        gridLayout_2->addWidget(label_7, 6, 3, 1, 1);

        label_10 = new QLabel(groupBox);
        label_10->setObjectName(QString::fromUtf8("label_10"));

        gridLayout_2->addWidget(label_10, 2, 3, 1, 1);

        label_8 = new QLabel(groupBox);
        label_8->setObjectName(QString::fromUtf8("label_8"));

        gridLayout_2->addWidget(label_8, 2, 6, 1, 1);

        tEdit_Sort10 = new QTextEdit(groupBox);
        tEdit_Sort10->setObjectName(QString::fromUtf8("tEdit_Sort10"));
        tEdit_Sort10->setEnabled(false);

        gridLayout_2->addWidget(tEdit_Sort10, 5, 6, 1, 1);

        lEdit_selfStaus = new QLineEdit(groupBox);
        lEdit_selfStaus->setObjectName(QString::fromUtf8("lEdit_selfStaus"));

        gridLayout_2->addWidget(lEdit_selfStaus, 7, 0, 1, 1);

        label_12 = new QLabel(groupBox);
        label_12->setObjectName(QString::fromUtf8("label_12"));

        gridLayout_2->addWidget(label_12, 2, 0, 1, 1);

        label_22 = new QLabel(groupBox);
        label_22->setObjectName(QString::fromUtf8("label_22"));

        gridLayout_2->addWidget(label_22, 6, 0, 1, 1);

        lEdit_selfBar = new QLineEdit(groupBox);
        lEdit_selfBar->setObjectName(QString::fromUtf8("lEdit_selfBar"));

        gridLayout_2->addWidget(lEdit_selfBar, 7, 2, 1, 1);

        label_23 = new QLabel(groupBox);
        label_23->setObjectName(QString::fromUtf8("label_23"));

        gridLayout_2->addWidget(label_23, 6, 2, 1, 1);

        tEdit_selfCurAngle = new QLineEdit(groupBox);
        tEdit_selfCurAngle->setObjectName(QString::fromUtf8("tEdit_selfCurAngle"));

        gridLayout_2->addWidget(tEdit_selfCurAngle, 7, 3, 1, 1);

        label_13 = new QLabel(groupBox);
        label_13->setObjectName(QString::fromUtf8("label_13"));

        gridLayout_2->addWidget(label_13, 6, 4, 1, 1);

        tEdit_selfCurAccCnt = new QLineEdit(groupBox);
        tEdit_selfCurAccCnt->setObjectName(QString::fromUtf8("tEdit_selfCurAccCnt"));

        gridLayout_2->addWidget(tEdit_selfCurAccCnt, 7, 4, 1, 1);

        label_14 = new QLabel(groupBox);
        label_14->setObjectName(QString::fromUtf8("label_14"));

        gridLayout_2->addWidget(label_14, 6, 6, 1, 1);

        lineEditlog = new QLineEdit(groupBox);
        lineEditlog->setObjectName(QString::fromUtf8("lineEditlog"));

        gridLayout_2->addWidget(lineEditlog, 7, 6, 1, 1);


        gridLayout_3->addWidget(groupBox, 0, 0, 2, 1);

        groupBox_3 = new QGroupBox(DialogExtendInfo);
        groupBox_3->setObjectName(QString::fromUtf8("groupBox_3"));
        groupBox_3->setStyleSheet(QString::fromUtf8("QGroupBox {\n"
"     border: 1.5px solid green;\n"
"     margin-top:2ex; \n"
"}\n"
"\n"
"QGroupBox::title {\n"
"     subcontrol-origin: margin;\n"
"     position: relative;\n"
"     left: 4px;\n"
"	 font: 16pt \"\351\273\221\344\275\223\";\n"
"}\n"
""));
        gridLayout = new QGridLayout(groupBox_3);
        gridLayout->setObjectName(QString::fromUtf8("gridLayout"));
        horizontalLayout_2 = new QHBoxLayout();
        horizontalLayout_2->setObjectName(QString::fromUtf8("horizontalLayout_2"));
        lb_tunnelFence = new QLabel(groupBox_3);
        lb_tunnelFence->setObjectName(QString::fromUtf8("lb_tunnelFence"));
        lb_tunnelFence->setAlignment(Qt::AlignCenter);

        horizontalLayout_2->addWidget(lb_tunnelFence);


        gridLayout->addLayout(horizontalLayout_2, 1, 0, 1, 1);

        horizontalLayout = new QHBoxLayout();
        horizontalLayout->setObjectName(QString::fromUtf8("horizontalLayout"));
        lb_ruralScene = new QLabel(groupBox_3);
        lb_ruralScene->setObjectName(QString::fromUtf8("lb_ruralScene"));
        lb_ruralScene->setStyleSheet(QString::fromUtf8(""));
        lb_ruralScene->setAlignment(Qt::AlignCenter);

        horizontalLayout->addWidget(lb_ruralScene);


        gridLayout->addLayout(horizontalLayout, 0, 0, 1, 1);

        horizontalLayout_3 = new QHBoxLayout();
        horizontalLayout_3->setObjectName(QString::fromUtf8("horizontalLayout_3"));
        lb_fenceScene = new QLabel(groupBox_3);
        lb_fenceScene->setObjectName(QString::fromUtf8("lb_fenceScene"));
        lb_fenceScene->setAlignment(Qt::AlignCenter);

        horizontalLayout_3->addWidget(lb_fenceScene);


        gridLayout->addLayout(horizontalLayout_3, 0, 1, 1, 1);

        horizontalLayout_4 = new QHBoxLayout();
        horizontalLayout_4->setObjectName(QString::fromUtf8("horizontalLayout_4"));
        lb_barnScene = new QLabel(groupBox_3);
        lb_barnScene->setObjectName(QString::fromUtf8("lb_barnScene"));
        lb_barnScene->setAlignment(Qt::AlignCenter);

        horizontalLayout_4->addWidget(lb_barnScene);


        gridLayout->addLayout(horizontalLayout_4, 1, 1, 1, 1);


        gridLayout_3->addWidget(groupBox_3, 0, 1, 1, 1);

        groupBox_2 = new QGroupBox(DialogExtendInfo);
        groupBox_2->setObjectName(QString::fromUtf8("groupBox_2"));
        groupBox_2->setStyleSheet(QString::fromUtf8("QGroupBox {\n"
"     border: 1.5px solid green;\n"
"     margin-top:2ex; \n"
"}\n"
"\n"
"QGroupBox::title {\n"
"     subcontrol-origin: margin;\n"
"     position: relative;\n"
"     left: 4px;\n"
"	 font: 16pt \"\351\273\221\344\275\223\";\n"
"}\n"
""));
        gridLayout_4 = new QGridLayout(groupBox_2);
        gridLayout_4->setObjectName(QString::fromUtf8("gridLayout_4"));
        gridLayout_4->setHorizontalSpacing(6);
        gridLayout_4->setVerticalSpacing(0);
        gridLayout_4->setContentsMargins(9, 9, -1, -1);
        label_6 = new QLabel(groupBox_2);
        label_6->setObjectName(QString::fromUtf8("label_6"));

        gridLayout_4->addWidget(label_6, 9, 0, 1, 1);

        label_24 = new QLabel(groupBox_2);
        label_24->setObjectName(QString::fromUtf8("label_24"));

        gridLayout_4->addWidget(label_24, 0, 0, 1, 1);

        lEdit_loopTime = new QLineEdit(groupBox_2);
        lEdit_loopTime->setObjectName(QString::fromUtf8("lEdit_loopTime"));

        gridLayout_4->addWidget(lEdit_loopTime, 8, 1, 1, 2);

        label_20 = new QLabel(groupBox_2);
        label_20->setObjectName(QString::fromUtf8("label_20"));

        gridLayout_4->addWidget(label_20, 8, 0, 1, 1);

        lEdit_VerticalAngle_Y = new QLineEdit(groupBox_2);
        lEdit_VerticalAngle_Y->setObjectName(QString::fromUtf8("lEdit_VerticalAngle_Y"));

        gridLayout_4->addWidget(lEdit_VerticalAngle_Y, 14, 1, 1, 2);

        label_29 = new QLabel(groupBox_2);
        label_29->setObjectName(QString::fromUtf8("label_29"));

        gridLayout_4->addWidget(label_29, 10, 0, 1, 1);

        lEdit_AgcSW = new QLineEdit(groupBox_2);
        lEdit_AgcSW->setObjectName(QString::fromUtf8("lEdit_AgcSW"));

        gridLayout_4->addWidget(lEdit_AgcSW, 6, 1, 1, 2);

        label_15 = new QLabel(groupBox_2);
        label_15->setObjectName(QString::fromUtf8("label_15"));

        gridLayout_4->addWidget(label_15, 4, 0, 1, 1);

        label_18 = new QLabel(groupBox_2);
        label_18->setObjectName(QString::fromUtf8("label_18"));

        gridLayout_4->addWidget(label_18, 6, 0, 1, 1);

        label_19 = new QLabel(groupBox_2);
        label_19->setObjectName(QString::fromUtf8("label_19"));

        gridLayout_4->addWidget(label_19, 7, 0, 1, 1);

        lEdit_speedmode = new QLineEdit(groupBox_2);
        lEdit_speedmode->setObjectName(QString::fromUtf8("lEdit_speedmode"));

        gridLayout_4->addWidget(lEdit_speedmode, 11, 1, 1, 2);

        lEdit_installAngle = new QLineEdit(groupBox_2);
        lEdit_installAngle->setObjectName(QString::fromUtf8("lEdit_installAngle"));
        lEdit_installAngle->setMinimumSize(QSize(50, 0));

        gridLayout_4->addWidget(lEdit_installAngle, 0, 1, 1, 2);

        label_26 = new QLabel(groupBox_2);
        label_26->setObjectName(QString::fromUtf8("label_26"));

        gridLayout_4->addWidget(label_26, 14, 0, 1, 1);

        lEdit_horizontalOffset = new QLineEdit(groupBox_2);
        lEdit_horizontalOffset->setObjectName(QString::fromUtf8("lEdit_horizontalOffset"));

        gridLayout_4->addWidget(lEdit_horizontalOffset, 12, 1, 1, 2);

        label_27 = new QLabel(groupBox_2);
        label_27->setObjectName(QString::fromUtf8("label_27"));

        gridLayout_4->addWidget(label_27, 13, 0, 1, 1);

        lEdit_ProtocolVer = new QLineEdit(groupBox_2);
        lEdit_ProtocolVer->setObjectName(QString::fromUtf8("lEdit_ProtocolVer"));

        gridLayout_4->addWidget(lEdit_ProtocolVer, 15, 1, 1, 2);

        label_21 = new QLabel(groupBox_2);
        label_21->setObjectName(QString::fromUtf8("label_21"));

        gridLayout_4->addWidget(label_21, 11, 0, 1, 1);

        lEdit_EOLVAngleOffset = new QLineEdit(groupBox_2);
        lEdit_EOLVAngleOffset->setObjectName(QString::fromUtf8("lEdit_EOLVAngleOffset"));

        gridLayout_4->addWidget(lEdit_EOLVAngleOffset, 1, 1, 1, 2);

        label_30 = new QLabel(groupBox_2);
        label_30->setObjectName(QString::fromUtf8("label_30"));

        gridLayout_4->addWidget(label_30, 2, 0, 1, 1);

        label_16 = new QLabel(groupBox_2);
        label_16->setObjectName(QString::fromUtf8("label_16"));

        gridLayout_4->addWidget(label_16, 1, 0, 1, 1);

        label_25 = new QLabel(groupBox_2);
        label_25->setObjectName(QString::fromUtf8("label_25"));

        gridLayout_4->addWidget(label_25, 12, 0, 1, 1);

        label_17 = new QLabel(groupBox_2);
        label_17->setObjectName(QString::fromUtf8("label_17"));

        gridLayout_4->addWidget(label_17, 5, 0, 1, 1);

        lEdit_selfAngle = new QLineEdit(groupBox_2);
        lEdit_selfAngle->setObjectName(QString::fromUtf8("lEdit_selfAngle"));

        gridLayout_4->addWidget(lEdit_selfAngle, 9, 1, 1, 2);

        label_28 = new QLabel(groupBox_2);
        label_28->setObjectName(QString::fromUtf8("label_28"));

        gridLayout_4->addWidget(label_28, 15, 0, 1, 1);

        lEdit_AgcType = new QLineEdit(groupBox_2);
        lEdit_AgcType->setObjectName(QString::fromUtf8("lEdit_AgcType"));

        gridLayout_4->addWidget(lEdit_AgcType, 7, 1, 1, 2);

        lEdit_mcuTemperature = new QLineEdit(groupBox_2);
        lEdit_mcuTemperature->setObjectName(QString::fromUtf8("lEdit_mcuTemperature"));

        gridLayout_4->addWidget(lEdit_mcuTemperature, 4, 1, 1, 2);

        lEdit_selfAnglePit = new QLineEdit(groupBox_2);
        lEdit_selfAnglePit->setObjectName(QString::fromUtf8("lEdit_selfAnglePit"));

        gridLayout_4->addWidget(lEdit_selfAnglePit, 10, 1, 1, 1);

        lEdit_mmicTemperature = new QLineEdit(groupBox_2);
        lEdit_mmicTemperature->setObjectName(QString::fromUtf8("lEdit_mmicTemperature"));

        gridLayout_4->addWidget(lEdit_mmicTemperature, 5, 1, 1, 2);

        lEdit_VerticalAngle_X = new QLineEdit(groupBox_2);
        lEdit_VerticalAngle_X->setObjectName(QString::fromUtf8("lEdit_VerticalAngle_X"));

        gridLayout_4->addWidget(lEdit_VerticalAngle_X, 13, 1, 1, 2);

        label_31 = new QLabel(groupBox_2);
        label_31->setObjectName(QString::fromUtf8("label_31"));

        gridLayout_4->addWidget(label_31, 3, 0, 1, 1);

        lEdit_servAnglePit = new QLineEdit(groupBox_2);
        lEdit_servAnglePit->setObjectName(QString::fromUtf8("lEdit_servAnglePit"));

        gridLayout_4->addWidget(lEdit_servAnglePit, 3, 1, 1, 2);

        lEdit_servAngleHrz = new QLineEdit(groupBox_2);
        lEdit_servAngleHrz->setObjectName(QString::fromUtf8("lEdit_servAngleHrz"));

        gridLayout_4->addWidget(lEdit_servAngleHrz, 2, 1, 1, 2);


        gridLayout_3->addWidget(groupBox_2, 1, 1, 1, 1);


        retranslateUi(DialogExtendInfo);

        QMetaObject::connectSlotsByName(DialogExtendInfo);
    } // setupUi

    void retranslateUi(QDialog *DialogExtendInfo)
    {
        DialogExtendInfo->setWindowTitle(QCoreApplication::translate("DialogExtendInfo", "Dialog", nullptr));
        groupBox->setTitle(QCoreApplication::translate("DialogExtendInfo", "\347\233\256\346\240\207\345\210\206\347\261\273", nullptr));
        label_3->setText(QCoreApplication::translate("DialogExtendInfo", "\345\244\247\350\275\246\357\274\232", nullptr));
        label_2->setText(QCoreApplication::translate("DialogExtendInfo", "\345\260\217\350\275\246\357\274\232", nullptr));
        label->setText(QCoreApplication::translate("DialogExtendInfo", "\344\272\272/\347\224\265\345\212\250\350\275\246/\350\207\252\350\241\214\350\275\246\357\274\232", nullptr));
        label_9->setText(QCoreApplication::translate("DialogExtendInfo", "\346\212\244\346\240\217/\346\240\221\357\274\232", nullptr));
        label_4->setText(QCoreApplication::translate("DialogExtendInfo", "\346\235\245\345\220\221\357\274\232", nullptr));
        label_5->setText(QCoreApplication::translate("DialogExtendInfo", "\351\235\231\346\255\242\357\274\232", nullptr));
        label_11->setText(QCoreApplication::translate("DialogExtendInfo", "\345\244\251\346\241\245/\350\267\257\347\211\214\357\274\232", nullptr));
        label_7->setText(QCoreApplication::translate("DialogExtendInfo", "\346\234\254\346\254\241\347\247\257\347\264\257\347\233\256\346\240\207\344\270\252\346\225\260\357\274\232", nullptr));
        label_10->setText(QCoreApplication::translate("DialogExtendInfo", "\345\216\273\345\220\221\357\274\232", nullptr));
        label_8->setText(QCoreApplication::translate("DialogExtendInfo", "\347\273\235\345\257\271\351\235\231\346\255\242\347\211\251\357\274\232", nullptr));
        label_12->setText(QCoreApplication::translate("DialogExtendInfo", "\347\247\273\345\212\250\347\232\204\347\211\251\344\275\223\357\274\232", nullptr));
        label_22->setText(QCoreApplication::translate("DialogExtendInfo", "\350\207\252\346\240\207\345\256\232\347\212\266\346\200\201\357\274\232", nullptr));
        label_23->setText(QCoreApplication::translate("DialogExtendInfo", "\350\207\252\346\240\207\345\256\232\346\254\241\346\225\260/\350\277\233\345\272\246:", nullptr));
        label_13->setText(QCoreApplication::translate("DialogExtendInfo", "\345\275\223\345\211\215\346\254\241\347\232\204\350\256\241\347\256\227\350\247\222\345\272\246\357\274\232", nullptr));
        label_14->setText(QCoreApplication::translate("DialogExtendInfo", "log", nullptr));
        groupBox_3->setTitle(QCoreApplication::translate("DialogExtendInfo", "\345\234\272\346\231\257\345\210\206\347\261\273", nullptr));
        lb_tunnelFence->setText(QCoreApplication::translate("DialogExtendInfo", "\351\232\247\351\201\223\345\234\272\346\231\257", nullptr));
        lb_ruralScene->setText(QCoreApplication::translate("DialogExtendInfo", "\344\271\241\346\235\221\351\201\223\350\267\257", nullptr));
        lb_fenceScene->setText(QCoreApplication::translate("DialogExtendInfo", "\346\240\217\346\235\206\345\234\272\346\231\257", nullptr));
        lb_barnScene->setText(QCoreApplication::translate("DialogExtendInfo", "\345\234\260\344\270\213\350\275\246\345\272\223", nullptr));
        groupBox_2->setTitle(QCoreApplication::translate("DialogExtendInfo", "\345\205\266\344\273\226", nullptr));
        label_6->setText(QCoreApplication::translate("DialogExtendInfo", "\350\207\252\346\240\207\345\256\232\350\241\245\345\201\277\345\200\274:", nullptr));
        label_24->setText(QCoreApplication::translate("DialogExtendInfo", "\344\270\213\347\272\277\346\260\264\345\271\263\350\247\222\345\272\246\357\274\232", nullptr));
        label_20->setText(QCoreApplication::translate("DialogExtendInfo", "LoopTime:", nullptr));
        label_29->setText(QCoreApplication::translate("DialogExtendInfo", "\350\207\252\346\240\207\345\256\232\350\241\245\345\201\277\345\200\274(PIT):", nullptr));
        lEdit_AgcSW->setPlaceholderText(QString());
        label_15->setText(QCoreApplication::translate("DialogExtendInfo", "MCU\346\270\251\345\272\246\357\274\232", nullptr));
        label_18->setText(QCoreApplication::translate("DialogExtendInfo", "AGC SW:", nullptr));
        label_19->setText(QCoreApplication::translate("DialogExtendInfo", "AGC TYPE:", nullptr));
        label_26->setText(QCoreApplication::translate("DialogExtendInfo", "\345\256\211\350\243\205\344\277\257\344\273\260\350\247\222Y\357\274\232", nullptr));
        label_27->setText(QCoreApplication::translate("DialogExtendInfo", "\345\256\211\350\243\205\344\277\257\344\273\260\350\247\222X\357\274\232", nullptr));
        label_21->setText(QCoreApplication::translate("DialogExtendInfo", "\351\200\237\345\272\246\346\250\241\345\274\217:", nullptr));
        label_30->setText(QCoreApplication::translate("DialogExtendInfo", "\346\234\215\345\212\241\346\260\264\345\271\263\350\247\222\345\272\246\357\274\232", nullptr));
        label_16->setText(QCoreApplication::translate("DialogExtendInfo", "\344\270\213\347\272\277\344\277\257\344\273\260\350\247\222\345\272\246\357\274\232", nullptr));
        label_25->setText(QCoreApplication::translate("DialogExtendInfo", "\346\260\264\345\271\263\345\201\217\347\247\273\357\274\232", nullptr));
        label_17->setText(QCoreApplication::translate("DialogExtendInfo", "\345\272\225\345\231\252\345\200\274\357\274\232", nullptr));
        label_28->setText(QCoreApplication::translate("DialogExtendInfo", "\345\215\217\350\256\256\347\211\210\346\234\254\357\274\232", nullptr));
        label_31->setText(QCoreApplication::translate("DialogExtendInfo", "\346\234\215\345\212\241\344\277\257\344\273\260\350\247\222\345\272\246\357\274\232", nullptr));
    } // retranslateUi

};

namespace Ui {
    class DialogExtendInfo: public Ui_DialogExtendInfo {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_DIALOGEXTENDINFO_H
