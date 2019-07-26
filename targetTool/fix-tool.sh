OUTPUT_HEADER_FOLDER="`pwd`/result"
rm -rf $OUTPUT_HEADER_FOLDER
mkdir $OUTPUT_HEADER_FOLDER
cp *.h "$OUTPUT_HEADER_FOLDER/"
cp *.c "$OUTPUT_HEADER_FOLDER/"

find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libavformat\///g" {} \;
find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libavutil\///g" {} \;
find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libavcodec\///g" {} \;
find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libavfilter\///g" {} \;
find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libavdevice\///g" {} \;
find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libswresample\///g" {} \;
find $OUTPUT_HEADER_FOLDER -type f -exec sed -i '' "s/libswscale\///g" {} \;

#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libavformatVersion' "s/libavformat\/version//g" {} \;
#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libavutilVersion' "s/libavutil\/version//g" {} \;
#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libavcodecVersion' "s/libavcodec\/version//g" {} \;
#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libavfilterVersion' "s/libavfilter\/version//g" {} \;
#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libavdeviceVersion' "s/libavdevice\/version//g" {} \;
#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libswresampleVersion' "s/libswresample\/version//g" {} \;
#find $OUTPUT_HEADER_FOLDER -type f -exec sed -i 'libswscaleVersion' "s/libswscale\/version//g" {} \;
