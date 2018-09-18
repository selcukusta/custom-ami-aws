FROM microsoft/dotnet:2.1-sdk-alpine AS build-env
COPY ./src ./app
WORKDIR /app
RUN dotnet publish -c Release -o publish-folder -r linux-musl-x64
# build runtime image
FROM microsoft/dotnet:2.1-aspnetcore-runtime-alpine
COPY --from=build-env /app/publish-folder ./
ENV ASPNETCORE_URLS=http://*:80
EXPOSE 80
ENTRYPOINT ["dotnet", "aws-sample.dll"]