字既排位同關聯字先後，以香港常用語為先｜關聯字可以到lua/assoc_words.txt自行修改｜有教學放左起：fullstroke_g6_user_guide｜Rime本體請去官網Download: https://rime.im/

本方案為基於 Rime 引擎重新編寫嘅全筆劃輸入法，按鍵佈局參考香港中文大學 G6 筆畫輸入法之鍵位設計，所有設定檔與 Lua 腳本均為獨立原創|
個人自用方案，歡迎自取，隨緣更新

設計理念：G6雖然已經update左 Win11版本，但真係打得有啲kick，所以試下用RIME整一個，務求Mac同Win都可以用到，雖然唔係100%似尚算用到的

## 安裝方法

1. 下載方案檔案

   前往本專案的 [Releases](https://github.com/carlyleung/fullstroke_g6) 頁面下載最新版本的 `.zip` 壓縮檔並解壓（或直接 `git clone` 本倉庫）。


2. 複製檔案至 Rime 用戶資料夾
   將解壓後的所有 `.yaml` 檔案（以及 `lua/` 資料夾，如有）複製到對應平台的 Rime 用戶資料夾：
   
    Windows（小狼毫 Weasel）： `%APPDATA%\Rime`（可於工作列右下角右鍵點擊小狼毫圖示 →「用戶資料夾」開啟）
    
    macOS（鼠鬚管 Squirrel）： `~/Library/Rime`（可於頂部選單列點擊輸入法圖示 →「用戶設定」開啟）
    
    (其他platform有可能用到，本人無test過)


3. 啟用輸入方案
   打開用戶資料夾內的 `default.custom.yaml`（若不存在請自行建立），加入以下設定以追加本方案（使用 `@next` 可避免覆蓋你原有的輸入方案）：

   ```yaml
   patch:
     "schema_list/@next":
       schema: fullstroke_g6
   ```


4. 重新部署
   點擊 Rime 選單中的「重新部署（Deploy）」，等待數秒完成編譯後，按 `Ctrl + ~`（或 `F4`）即可切換至本方案。
