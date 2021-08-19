/* eslint-disable no-restricted-globals */
/* eslint-disable no-alert */
import { LightningElement, api, track } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import getContentDetails from '@salesforce/apex/NatoutTripFilesService.getContentDetails';
import deleteContentDocument from '@salesforce/apex/NatoutTripFilesService.deleteContentDocument';
import saveTheChunkFile from '@salesforce/apex/NatoutTripFilesService.saveTheChunkFile';
import userId from '@salesforce/user/Id';
import { reduceErrors } from 'c/ldsUtils';

const MAX_FILE_SIZE = 5000000;
const CHUNK_SIZE = 750000;

export default class NatoutTripFiles extends LightningElement {
    @api recordId;
    @api fileCategory;
    @api userIsAdmin;
    isLoading = false;

    fileName = '';
    filesUploaded = [];
    isLoading = false;
    fileSize;
    @track dataList;
    editingPhotoName = false;
    photoCredit;

    connectedCallback() {
        this.handleSync();
    }

    deleteFile(event) {
        let rowNum = event.currentTarget.dataset.row;
        let row = this.dataList[rowNum];

        if( ! confirm('Are you sure you want to delete this file?')) {
            return;
        }
        this.isLoading = true;

        deleteContentDocument({
            recordId : row.ContentDocumentId
        })
        .then(() => {
            this.dataList  = this.dataList.filter(item => {
                return item.ContentDocumentId !== row.ContentDocumentId ;
            });
            rowNum = 0;
            this.dataList.forEach( file => {
                file.rowNum = rowNum++;
            });
        })
        .catch(error => {
            console.error('**** error **** \n ',error);
            this.showSnackbar('failure','Error','Error Deleting File');
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

    handleSync(){
        let imageExtensions = ['png','jpg','gif','jpeg'];
        let supportedIconExtensions = ['ai','attachment','audio','box_notes','csv','eps','excel','exe',
                        'flash','folder','gdoc','gdocs','gform','gpres','gsheet','html','image','keynote','library_folder',
                        'link','mp4','overlay','pack','pages','pdf','ppt','psd','quip_doc','quip_sheet','quip_slide',
                        'rtf','slide','stypi','txt','unknown','video','visio','webex','word','xml','zip'];

        this.isLoading = true;
        getContentDetails({
            recordId : this.recordId, fileCategory : this.fileCategory
        })
        .then(result => {
            let parsedData = JSON.parse(result);
            let stringifiedData = JSON.stringify(parsedData);
            let finalData = JSON.parse(stringifiedData);
            let baseUrl = this.getBaseUrl();
            let rowNum = 0;
            finalData.forEach(file => {
                file.downloadUrl = baseUrl+'sfc/servlet.shepherd/document/download/'+file.ContentDocumentId;
                file.fileUrl     = baseUrl+'sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&amp;versionId='+file.Id;
                file.Size        = this.formatBytes(file.ContentDocument.ContentSize, 2);
                file.displayTitle = file.Title;
                file.rowNum = rowNum++;
                if(file.Photo_Credit__c) {
                    file.displayTitle += ' photo by: ' + file.Photo_Credit__c;
                }

                let fileType = file.ContentDocument.FileType.toLowerCase();
                if(imageExtensions.includes(fileType)){
                    file.icon = 'doctype:image';
                    file.isImage = true;
                }else{
                    file.isImage = false;
                    if(fileType === 'word_x') {
                        fileType = 'word';
                    }
                    if(supportedIconExtensions.includes(fileType)){
                        file.icon = 'doctype:' + fileType;
                    }
                }

                let canDelete = false;
                if(file.ContentDocument.CreatedById === userId) {
                    canDelete = true;
                }
                else if(this.userIsAdmin) {
                    canDelete = true;
                }
                file.canDelete = canDelete;
            });
            this.dataList = finalData;
        })
        .catch(error => {
            console.error('**** error **** \n ',error);
            this.showSnackbar('failure','Error','Error Retrieving Files');
        })
        .finally(()=>{
            this.isLoading = false;
        });
    }

    handleFilesChange(event) {
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files;
            this.fileName = event.target.files[0].name;
        }
    }

    saveFile() {
        if(this.filesUploaded.length === 0) {
            this.showSnackbar('failure','Error','You must select a file - Click \'Upload Files\'');
            return;
        }
        let fileCon = this.filesUploaded[0];
        this.fileSize = this.formatBytes(fileCon.size, 2);
        if (fileCon.size > MAX_FILE_SIZE) {
            let message = 'File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' + 'Selected file size: ' + fileCon.size;
            this.showSnackbar('failure','Error',message);
            return;
        }
        let reader = new FileReader();
        let self = this;
        reader.onload = function() {
            var fileContents = reader.result;
            var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
            fileContents = fileContents.substring(dataStart);
            self.upload(fileCon, fileContents);
        };
        reader.readAsDataURL(fileCon);
    }

    upload(file, fileContents){
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
        
        this.uploadChunk(file, fileContents, fromPos, toPos, ''); 
    }

    uploadChunk(file, fileContents, fromPos, toPos, attachId){
        this.isLoading = true;
        let chunk = fileContents.substring(fromPos, toPos);
        
        saveTheChunkFile({ 
            parentId: this.recordId,
            fileName: file.name,
            base64Data: encodeURIComponent(chunk), 
            contentType: file.type,
            fileId: attachId,
            category: this.fileCategory
        })
        .then(result => {            
            attachId = result;
            fromPos = toPos;
            toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);    
            if (fromPos < toPos) {
                this.uploadChunk(file, fileContents, fromPos, toPos, attachId);  
            }else{
                this.fileName='';
                this.fileSize=null;
                this.filesUploaded=[];
                this.handleSync();
            }
        })
        .catch(error => {
            console.error('Error: ', error);
            this.showSnackbar('failure','Error','Error Uploading File');
        });
    }
    handleUpdate(row) {
        this.rowToUpdate = row;
        this.editingPhotoName = true;
    }
    editPhotographer(event) {
        let rowNum = event.currentTarget.dataset.row;
        this.rowToUpdate = this.dataList[rowNum];
        this.photoCredit = this.rowToUpdate.Photo_Credit__c;
        this.editingPhotoName = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(()=>{
            let input = this.template.querySelector('.photoname');
            input.focus();
        },100);
    }
    cancelSave() {
        this.editingPhotoName = false;
    }
    handleFieldChange(e) {
        this.photoCredit = e.target.value;
    }
    updateFile() {
        this.isLoading = true;
        updateRecord ({
            fields : {
                Id: this.rowToUpdate.Id,
                Photo_Credit__c: this.photoCredit
            }
        })
        .then(result => {
            this.message = result;
            this.error = undefined;
            this.handleSync();
        })
        .catch(error => {
            this.saveSuccessful = false;
            this.error = error;
            this.showSnackbar('failure','Update Failed',reduceErrors(error).join(', '));
        })
        .finally(()=>{
            this.editingPhotoName = false;
        });
    }

    formatBytes(bytes,decimals) {
        if(bytes === 0) return '0 Bytes';
        let k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }
    getBaseUrl(){
        let baseUrl = 'https://' + window.location.host + '/';
        return baseUrl;
    }
    showSnackbar(type, header, text) {
        this.template.querySelector('c-snackbar').show(type, header, text);
    }
    downloadToClient(event) {
        let rowNum = event.currentTarget.dataset.row;
        let row = this.dataList[rowNum];
        window.open(row.downloadUrl, "_blank");
    }
}